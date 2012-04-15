function DCPUCrt() {
    this.cpu = undefined;
    this.canvas = undefined;
    this.ctx = undefined;
    this.font = document.createElement("IMG");
    this.scanlines = document.createElement("IMG");
    this.glass = document.createElement("IMG");
    this.rollingbarposition = 0;
    this.buffer = [];
}

DCPUCrt.prototype.tick = function () {
    this.render();
};

DCPUCrt.prototype.render = function () {
    
    var offsety = 1 - Math.floor(Math.random() * 3);

    this.ctx.fillStyle = "rgb(0, 0, 0)";
    this.ctx.fillRect(0, 0, 512, 384);

    for (pos = 0x0000; pos < 0x0180; pos ++) {
	var c = this.cpu.memory[pos + 0x8000];
	if (c != 0) {
	     this.ctx.drawImage(this.font, 
	       ~~(c % 32) << 4, 
	       ~~(c >>> 5) << 5, 
	       15, 30, 
	       ~~(pos % 32) << 4, 
		(~~(pos >>> 5) << 5) + offsety, 
	       15, 30);
	    
	}


    }
    
    //this.ctx.drawImage(this.font,0, offsety, 512, 128);
    this.ctx.drawImage(this.scanlines,0, 0, 512, 384);
    this.ctx.fillStyle = "rgba(0, 0, 0, 0.2)";
    this.ctx.fillRect(0, this.rollingbarposition, 512, 60);
    this.ctx.drawImage(this.glass,0, 0, 512, 384);
    this.rollingbarposition += 2;
    if (this.rollingbarposition > 384) {
	this.rollingbarposition = -60;
    }

};

DCPUCrt.prototype.rollingbar = function () {
    this.ctx.fill
}

DCPUCrt.prototype.setcpu = function (cpu) {
    this.cpu = cpu;
};

DCPUCrt.prototype.init = function (cid, font) {
    this.canvas = document.getElementById(cid);
    this.ctx = this.canvas.getContext('2d');
    this.font.src = font;
    this.scanlines.src = "scanlines.png";
    this.glass.src = "glass.png";
}