(function() {
 }()
);

function DCPUCore() {
    //Options
    this._MEMORY_SIZE = 0x10000;
    this._MEM_DEFAULT = 0;
    this._REG_DEFAULT = 0;
    this._PC_DEFAULT = 0;
    this._SP_DEFAULT = 0;
    this._CPU_MHZ = 100;
    
    //OpCodes
    this.NOP = 0;	 
    this.RES = 0;  // -RESERVED- (This implementation treats as NOP)
    this.SET = 1;  // Sets value of b to a
    this.ADD = 2;  // Adds b to a, sets O
    this.SUB = 3;  // Subtracts b from a, sets O
    this.MUL = 4;  // Multiplies a by b, sets O
    this.DIV = 5;  // Divides a by b, sets O
    this.MOD = 6;  // Remainder of a over b
    this.SHL = 7;  // Shifts a left b places, sets O
    this.SHR = 8;  // Shifts a right b places, sets O
    this.AND = 9;  // Binary and of a and b
    this.BOR = 10; // Binary or of a and b
    this.XOR = 11; // Binary xor of a and b
    this.IFE = 12; // Skips one instruction if a!=b
    this.IFN = 13; // Skips one instruction if a==b
    this.IFG = 14; // Skips one instruction if a<=b
    this.IFB = 15; // Skips one instruction if (a&b)==0

    //Values
    //Various Value Codes (Parenthesis = memory lookup of value)
    this.REG = Number.range(0,8);		   //Register value - register values
    this.REG_MEM = Number.range(8,16);		   //(Register value) - value at address in registries
    this.MEM_OFFSET_REG = Number.range(16,24);	   //(Next word of ram + register value) - memory address offset by register value
    this.POP = 24;			   //Value at stack address, then increases stack counter
    this.PEEK = 25;			   //Value at stack address
    this.PUSH = 26;			   //Decreases stack address, then value at stack address
    this.SP = 27;			   //Current stack pointer value - current stack address
    this.PC = 28;			   //Program counter - current program counter
    this.O = 29;			   //Overflow - current value of the overflow
    this.MEM = 30;			   //(Next word of ram) - memory address
    this.MEM_LIT = 31;			   //Next word of ram - literal, does nothing on assign
    this.NUM_LIT = Number.range(32,64);	   //Literal value 0-31 - literal, does nothing on assign
    
    
    //opcodes------|bbbbbbaaaaaaoooo
    this._OP_PORTION = 0xF; 
    this._AV_PORTION = 0x3F0;
    this._BV_PORTION = 0xFC00;
    // Bit positions for the above
    this._OP_POSITION = 0; 
    this._AV_POSITION = 4; 
    this._BV_POSITION = 10;
    
    
    //registers (A, B, C, X, Y, Z, I, J)
    this._NUM_REGISTERS = 8;
    
    this.REGISTER_NAMES = ['SP', 'PC', 'O','A', 'B', 'C', 'X', 'Y', 'Z', 'I', 'J'];
    this.SPECIAL_REGISTERS = ['SP', 'PC', 'O'];
    this.LETTER_REGISTERS = ['A', 'B', 'C', 'X', 'Y', 'Z', 'I', 'J'];
    
    //All values are 16 bit unsigned
    this._MAX_VAL = 0xFFFF;
}

DCPUCore.prototype._buffer = function (size, default_value) {
    var b = new Uint16Array(size);
    for (i in b) {
	b[i] = default_value;
    }
    return b;
};

DCPUCore.prototype._init_cpu = function (size, num_registers) {
    this.memory = this._buffer(size, this._MEM_DEFAULT);
    this.registers = this._buffer(this._NUM_REGISTERS, this._REG_DEFAULT);
    this.pc = this._PC_DEFAULT;
    this.sp = this._SP_DEFAULT;
    this.o = false;
};

DCPUCore.prototype._has_overflown = function (val) {
    return (val < 0 || val > this._MAX_VAL);
};

DCPUCore.prototype._overflown = function (val) {
    this.o = this._has_overflown(val);
    return val & this._MAX_VAL;
};

DCPUCore.prototype._tick = function (op, a, b) {
    console.log("_tick, op:" + op + " a:"+a +" b:"+b);
    switch(op) {
    case this.NOP:
	return;
	break;
    case this.SET:
	a = b;
	return this._overflown(a);
	break;
    case this.ADD:
	a += b;
	return this._overflown(a);
	break;
    case this.SUB:
	a -= b;
	return this._overflown(a);
	break;
    case this.MUL:
	a *= b;
	return this._overflown(a);
	break;
    case this.DIV:
	a /= b;
	return this._overflown(a);
	break;
    case this.MOD:
	a %= b;
	return this._overflown(a);
	break;
    case this.SHL:
	a <<= b;
	return this._overflown(a);
	break;
    case this.SHR:
	a >>= b;
	return this._overflown(a);
	break;
    case this.AND:
	a &= b;
	return a;
	break;
    case this.BOR:
	a |= b;
	return a;
	break;
    case this.XOR:
	a ^= b;
	return a;
	break;
    case this.IFE:
	if (a != b) {
	    this.stepover = true;
	}
	return;
	break;
    case this.IFN:
	if (a == b) {
	    this.stepover = true;
	}
	return;
	break;
    case this.IFG:
	if (a <= b) {
	    this.stepover = true;
	}
	return;
	break;
    case this.IFB:
	if (! (a|b)) {
	    this._incPC();
	}
	return;
	break;
    default:
	this._abort("UNKNOWN OPCODE: " + op);
    }
};

DCPUCore.prototype._abort = function (message) {
    console.log(message + " " + JSON.stringify(this.registers) + " " + JSON.stringify(this.pc));
};

DCPUCore.prototype._set = function (target,value) {
    console.log("_set: " + target + " " + value);
    switch(target) {
    case 0:
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
    case 7:
	this.registers[target] = value;
	break;
    case 8:
    case 9:
    case 10:
    case 11:
    case 12:
    case 13:
    case 14:
    case 15:
	this.memory[this.registers[target-8]] = value;
	break;
    case 16:
    case 17:
    case 18:
    case 19:
    case 20:
    case 21:
    case 22:
    case 23:
	console.log("Memory + offset register");
	console.log("pc: " + this.pc);
        console.log("finaltarget:" + (this.memory[ this.pc + 1 ] + target - 16));
	this.memory[this.memory[this.pc+1]+target-16] = value;
	break;
    case 24:
	this.memory[this.sp++] = value;
	break;
    case 25:
	this.memory[this.sp] = value;
	break;
    case 26:
	this.memory[this.sp--] = value;
	break;
    case 27:
	this.sp = value;
	break;
    case 28:
	this.pc = value;
	break;
    case 29:
	this.o = value;
	break;
    case 30:
	this.memory[this.memory[this.pc+1]] = value;
	break;
	//Everything else would be assigning to a literal value, silently fails.
    }
};

DCPUCore.prototype._get = function (target) {
	var z = this._tget(target);
	if ((z != undefined) && (z != null)) {
		return z;
	} else {
		return 0;
	}
};

DCPUCore.prototype._tget = function (target) {
	//ALWAYS GET A BEFORE B - IF BOTH DO PC++ THEN IT WILL FAIL IF YOU GET B BEFORE A.
	switch(target) {
		case 0:
		case 1:
		case 2:
		case 3:
		case 4:
		case 5:
		case 6:
		case 7:
			return this.registers[target];
			break;
		case 8:
		case 9:
		case 10:
		case 11:
		case 12:
		case 13:
		case 14:
		case 15:
			return this.memory[this.registers[target-8]];
	                break;
		case 16:
		case 17:
		case 18:
		case 19:
		case 20:
		case 21:
		case 22:
		case 23:
			return this.memory[this.memory[this.pc++]+target-16];
			break;
		case 24:
	                return this.memory[this.sp++];
			break;
		case 25:
			return this.memory[this.sp++];
			break;
		case 26:
			return this.memory[--this.sp];
			break;
		case 27:
			return this.sp;
			break;
		case 28:
			return this.pc;
			break;
		case 29:
			return O;
			break;
		case 30:
                        return this.memory[this.memory[this.pc++]];
			break;
		case 31:
	                return this.memory[this.pc++];
			break;
		default:
			return (target-32);
			break;
	}
};

DCPUCore.prototype._setval = function (vc, f, justcheck) {
    console.log("_setval:" + vc + " " + f);
    if (vc in this.REG) {
	console.log("vc is register: " + vc);
	if (f == undefined) {
	    return this.registers[vc];
	}
	else {
	    this.registers[vc] = f;
	    return;
	}
    }

    if (vc in this.REG_MEM) {
	vc -= this.REG_MEM;
	if (f == undefined) {
	    return this.memory[this.registers[vc]];
	}
	else {
	    this.memory[this.registers[vc]] = f;
	    return;
	}
    }

    if (vc in this.MEM_OFFSET_REG) {
	vc -= this.MEM_OFFSET_REG[0];
	this._incPC();
	var nex_mem = this.memory[this.pc];
	var reg = this.registers[vc];
	vc = this._overflown(reg + next_mem);
	if (f == undefined) {
	    return this.memory[vc];
	}
	else {
	    this.memory[vc] = f;
	    return;
	}
    }

    if (vc == this.POP) {
	if (f == undefined) {
	    vc = this.memory[this.sp];
	}
	else {
	    this.memory[this.sp] = f;
	}
	this._incSP()
	return vc;
    }

    if (vc == this.PEEK) {
	if (f == undefined) {
	    return this.memory[this.sp];
	}
	else {
	    return;
	}
    }
    
    if (vc == this.PUSH) {
	console.log("push:"+this.sp+" "+f);
	if (f == undefined) {
	    return vc;
	}
	else {
	    this._decSP()
	    this.memory[this.sp] = f;
	    return
	}
    }

    if (vc == this.SP) {
	if (f == undefined) {
	    return this.sp;
	}
	else {
	    this.sp = f;
	}
    }

    if (vc == this.PC) {
	if (f == undefined) {
	    return this.pc;
	}
	else {
	    this.pc = f;
	}
    }

    if (vc == this.O) {
	if (f == undefined) {
	    return this.o;
	}
	else {
	    this.o = f;
	}
    }

    if (vc == this.MEM) {
	console.log("vc is mem");
	if (justcheck != undefined) {
	    return this.MEM;
	}
        this._incPC()
	if (f == undefined) {
	    return this.memory[this.memory[vc]];
	}
	else {
	    this.memory[this.memory[vc]] = f;
	}
    }

    if (vc == this.MEM_LIT) {
	if (f != undefined) {
	    return;
	}
	this._incPC();
	return this.memory[this.pc];
    }

    if (this.NUM_LIT.indexOf(vc) != -1) {
	if (f != undefined) {
	    return;
	}
	return vc - this.NUM_LIT[0]
    }

    this._abort("UNKNOWN VALUE CODE: " + vc);

};


DCPUCore.prototype._getval = function (vc) {
    return this._setval(vc, undefined);
};

DCPUCore.prototype._checkval = function (vc) {
    return this._setval(vc, undefined, undefined);
};

DCPUCore.prototype._incPC = function () {
    this.pc = this._overflown(this.pc + 1);
};

DCPUCore.prototype._incSP = function () {
    this.sp = this._overflown(this.sp + 1);
};

DCPUCore.prototype._decSP = function () {
    this.sp = this._overflown(this.sp - 1);
};

DCPUCore.prototype.tick = function () {
    var v = this.memory[this.pc];
    this._incPC();
    var op = (v & this._OP_PORTION) >>> this._OP_POSITION;
    var a = (v & this._AV_PORTION) >>> this._AV_POSITION;
    var b = (v & this._BV_PORTION) >>> this._BV_POSITION;
    console.log("op:" + op);
    console.log("a:" + a);
    console.log("b:" + b);

    var aval = this._get(a);
    var bval = this._get(b);

    console.log("aval:" + aval);
    console.log("bval:" + bval);
    if (!this.stepover) {
	var fval = this._tick(op, aval, bval);
	
	console.log("fval:"+fval);
	
	if (fval != undefined) {
	    fval = this._overflown(fval, true);
	    this._set(a, fval);
	}
    }
    else {
	console.log("stepping over: " + (this.pc -1));
	this.stepover = false; 
    }	
};

DCPUCore.prototype.load = function (buffer) {
    for (var pos in buffer) {
	this.memory[pos] = buffer[pos];
    }
};
    
DCPUCore.prototype.run = function () {
    this.tick();
    var cdt = (new Date()).getTime() / 1000;
    var dt = cdt - this.dt;
    this.dt = cdt;
    t = (1.0 / (this._CPU_MHZ + 1)) - dt;
    if (t > .001) {
	setTimeout("this.delayed(dt)", t);
    }
    return dt;
};

DCPUCore.prototype.delayed = function (dt) {
    return dt;
};

DCPUCore.prototype.__init__ = function () {
    this._init_cpu(this._MEMORY_SIZE, this._NUM_REGISTERS);
    this.stepover = false;
    this.dt = 0;
};


Number.range = function() {
  var start, end, step;
  var array = [];

  switch(arguments.length){
    case 0:
      throw new Error('range() expected at least 1 argument, got 0 - must be specified as [start,] stop[, step]');
      return array;
    case 1:
      start = 0;
      end = Math.floor(arguments[0]) - 1;
      step = 1;
      break;
    case 2:
    case 3:
    default:
      start = Math.floor(arguments[0]);
      end = Math.floor(arguments[1]) - 1;
      var s = arguments[2];
      if (typeof s === 'undefined'){
        s = 1;
      }
      step = Math.floor(s) || (function(){ throw new Error('range() step argument must not be zero'); })();
      break;
   }

  if (step > 0){
    for (var i = start; i <= end; i += step){
      array.push(i);
    }
  } else if (step < 0) {
    step = -step;
    if (start > end){
      for (var i = start; i > end + 1; i -= step){
        array.push(i);
      }
    }
  }
  return array;
};


