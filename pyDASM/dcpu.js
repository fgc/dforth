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
    this.REG = range(0,8);		   //Register value - register values
    this.REG_MEM = range(8,16);		   //(Register value) - value at address in registries
    this.MEM_OFFSET_REG = range(16,24);	   //(Next word of ram + register value) - memory address offset by register value
    this.POP = 24;			   //Value at stack address, then increases stack counter
    this.PEEK = 25;			   //Value at stack address
    this.PUSH = 26;			   //Decreases stack address, then value at stack address
    this.SP = 27;			   //Current stack pointer value - current stack address
    this.PC = 28;			   //Program counter - current program counter
    this.O = 29;			   //Overflow - current value of the overflow
    this.MEM = 30;			   //(Next word of ram) - memory address
    this.MEM_LIT = 31;			   //Next word of ram - literal, does nothing on assign
    this.NUM_LIT = range(32,64);	   //Literal value 0-31 - literal, does nothing on assign
    
    
    //opcodes------|bbbbbbaaaaaaoooo
    this._OP_PORTION = 0x000000FF; 
    this._AV_PORTION = 0x000FFF00;
    this._BV_PORTION = 0xFFF00000;
    // Bit positions for the above
    this._OP_POSITION = 0; 
    this._AV_POSITION = 4; 
    this._BV_POSITION = 10;
    
    
    //registers (A, B, C, X, Y, Z, I, J)
    this._NUM_REGISTERS = 8;
    
    this.REGISTER_NAMES = ['SP', 'PC', 'O'];
    this.SPECIAL_REGISTERS = list(REGISTER_NAMES);
    this.LETTER_REGISTERS = ('A', 'B', 'C', 'X', 'Y', 'Z', 'I', 'J');
    this.REGISTER_NAMES += LETTER_REGISTERS;
    
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
    switch(op) {
    case this.NOP:
	return;
	break;
    case this.SET:
	b = a;
	return this._overflown(b); //???????????????????
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
	    this._incPC();
	}
	return;
	break;
    case this.IFN:
	if (a == b) {
	    this._incPC();
	}
	return;
	break;
    case this.IFG:
	if (a <= b) {
	    this._incPC();
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
    console.log(message + " " + JSON.stringify(this));
};

DCPUCore.prototype._setval = function (vc, f) {
    if (this.REG[vc] != undefined) {
	if (f == undefined) {
	    return this.REG[vc];
	}
	else {
	    this.REG[vc] = f;
	    return;
	}
    }
    if (this.REG_MEM[vc] != undefined) {
	vc -= self.MEM_OFFSET_REG[0];
	if (f == undefined) {
	    return this.memory[this.registers[vc]];
	}
	else {
	    this.memory[this.registers[vc]] = f;
	    return;
	}
    }
    if (this.REG[vc] != undefined) {
	if (f == undefined) {
	    return this.REG[vc];
	}
	else {
	    this.REG[vc] = f;
	    return;
	}
    }

};


