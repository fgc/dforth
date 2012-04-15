function DCPUKeyboard() {
}

DCPUKeyboard.prototype.tick = function () {
};

DCPUKeyboard.prototype.setcpu = function (cpu) {
    this.cpu = cpu;
};

DCPUKeyboard.prototype.init = function () {
    this.pointer = 0x9000;
    this.lastpointeraddr = 0x9010;
    this.offset = 0;
    var self = this;
    document.onkeydown = function(e) {
	console.log("Key event:",e,self.offset);
	var addr = self.pointer + self.offset;
	if (self.cpu.memory[addr] == 0) {
	    self.cpu.memory[addr] = e.keyCode;
	    self.cpu.memory[self.lastpointeraddr] = addr;
	    self.offset += 1;
	    self.offset &= 0x0f;
	}
    }
};