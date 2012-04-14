function DCPUCore() {

    this._CPU_MHZ = 100;

    this._OP_PART = 0xF; 
    this._AV_PART = 0x3F0;
    this._BV_PART = 0xFC00;

    this._OP_POS = 0; 
    this._AV_POS = 4; 
    this._BV_POS = 10;
    
    this._MAX_VAL = 0xFFFF;

    this.plugins = [];
}

DCPUCore.prototype._buffer = function (size, value) {
    var b = new Uint16Array(size);
    for (i in b) {
	b[i] = value;
    }
    return b;
};

DCPUCore.prototype._init_cpu = function (size, num_registers) {
    this.memory = this._buffer(size, 0);
    this.registers = this._buffer(num_registers, 0);
    this.pc = 0;
    this.sp = 0;
    this.o = 0x0000;
};

DCPUCore.prototype._has_overflown = function (val) {
    return (val < 0 || val > this._MAX_VAL);
};

DCPUCore.prototype._overflown = function (val) {
    this.o = this._has_overflown(val)?0x0001:0x0000; //Wrong, this is op-specific
    return val & this._MAX_VAL;
};

DCPUCore.prototype._nbop = function (nbop, a) {
    console.log("nbop:", nbop, a);
    switch(nbop) {
    case 0x01: //JSR
	--this.sp
	this.sp &= 0xFFFF;
	this.memory[this.sp] = this.pc;
	this.pc = a;
	return;
    default:
	this._abort ("UNKNOWN NON-BASIC OP");
    }
};

DCPUCore.prototype._op = function (op, a, b) {
    switch(op) {
    case 0x1: //SET
	return this._overflown(b);
    case 0x2: //ADD
	a += b;
	return this._overflown(a);
    case 0x3: //SUB
	a -= b;
	return this._overflown(a);
    case 0x4: //MUL
	a *= b;
	return this._overflown(a);
    case 0x5: //DIV
	a /= b;
	return this._overflown(a);
    case 0x6: //MOD
	a %= b;
	return this._overflown(a);
    case 0x7: //SHL
	a <<= b;
	return this._overflown(a);
    case 0x8: //SHR
	a >>= b;
	return this._overflown(a);
    case 0x9: //AND
	a &= b;
	return a;
    case 0xa: //BOR
	a |= b;
	return a;
    case 0xb: //XOR
	a ^= b;
	return a;
    case 0xc: //IFE
	if (a != b) {
	    this.stepover = true;
	}
	return;
    case 0xd: //IFN
	if (a == b) {
	    this.stepover = true;
	}
	return;
    case 0xe: //IFG
	if (a <= b) {
	    this.stepover = true;
	}
	return;
    case 0xf: //IFB
	if ((a&b) == 0) {
	    this.stepover = true;
	}
	return;
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
	this.memory[this.destpointer] = value;
	break;
    case 24:
	this._abort("CANNOT SET POP");
	break;
    case 25:
	this.memory[this.sp] = value;
	break;
    case 26:
	--this.sp;
	this.sp &= 0xFFFF;
	this.memory[this.sp] = value;
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
	this.memory[this.destpointer] = value;
	break;
    default:
	this._abort("CANNOT SET TO LITERAL VALUE");
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
	this.lastpointer = this.memory[this.pc++] + this.registers[target-16];
	return this.memory[this.lastpointer];
	break;
    case 24:
	return this.memory[this.sp++]; //stack can underflow into the start of RAM!!!
	break;
    case 25:
	return this.memory[this.sp];
	break;
    case 26:
	this._abort("CANNOT GET A VALUE FROM PUSH");
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
	this.lastpointer = this.memory[this.pc++];
        return this.memory[this.lastpointer];
	break;
    case 31:
	return this.memory[this.pc++];
	break;
    default:
	return (target-32);
	break;
    }
};

DCPUCore.prototype.tick = function () {
    var v = this.memory[this.pc++];
    if (!this.stepover) {
	this.lastpointer = undefined;
	this.destpointer = undefined;
	
	var op = (v & this._OP_PART) >>> this._OP_POS;
	
	if (op == 0x0) {
	    var nbop = (v & this._AV_PART) >>> this._AV_POS;
	    var a = (v & this._BV_PART) >>> this._BV_POS;
	    this._nbop(nbop, this._get(a));
	}
	else {

	    var a = (v & this._AV_PART) >>> this._AV_POS;
	    var b = (v & this._BV_PART) >>> this._BV_POS;
	    
	    var aval = this._get(a);
	    if (this.lastpointer != undefined) {
		this.destpointer = this.lastpointer;
	    }
	    var bval = this._get(b);
	    
	    var fval = this._op(op, aval, bval);
	    
	    if (fval != undefined) {
		fval = this._overflown(fval, true);
		this._set(a, fval);
	    }
	}

    }
    else {
	this.stepover = false; 
    }
    
    for (var pi in this.plugins) {
	this.plugins[pi].tick();
    }
};

DCPUCore.prototype.load = function (buffer) {
    for (var pos in buffer) {
	this.memory[pos] = buffer[pos];
    }
};

DCPUCore.prototype.register_plugin = function (plugin) {
    plugin.setcpu(this);
    this.plugins.push(plugin);
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
    this._init_cpu(0x10000, 8);
    this.stepover = false;
    this.dt = 0;
};