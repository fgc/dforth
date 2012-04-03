var dasm = require('./dasm');

console.log(dasm.parse(":kkza set a,b set a,0xFF\nand a,10 set x,kkza set i,[12] set j,[a] set z,[kkza] set a,[0xbeef + i]"));