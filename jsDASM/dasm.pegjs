{
    var macros = {};
}
dasm
    = lines:(jsr / dat / op / label)+ {
	var labels = {};
	var offset = 0;
	var output = [];

        function predelabelize(param) {
            if (param.symbaddr != undefined) {
                 return [30,param.symbaddr];
            }
	    if (param.label != undefined) {
	         return [31,param];
	    }
	    return param;
	}
	
	function postdelabelize(program) {
	    console.log("pdlabel labels: ", labels);
	    console.log("pdlabel program: ", program);
	    for (var pos in program) {
	        var cell = program[pos];
		console.log("pdlabel pos:",pos,"cell:", cell);
		if (cell.label != undefined) {
		    program[pos] = labels[cell.label];
		}
	    }
	    return program;	    
	}

	for (var i in lines) {
	    var line = lines[i];

	    console.log("offset:",offset, "line:" , JSON.stringify(line));

	    if (line.label != undefined) {
		labels[line.label.label] = offset;
	    }

	    else if (line.data != undefined) {
	        if (line.data.str != undefined) {
		   for (var i = 0; i < line.data.str.length; i++) {
		       output.push(line.data.str.charCodeAt(i));
		   }
		   offset += line.data.str.length;
		}
	        else if (line.data.label != undefined) {
		    output.push(line.data);
                offset++;
		}
		else {		
                output.push(line.data);
                offset++;
		}

	    }
	    
	    else if (line.jsr != undefined) {
		var zeroop = 0;
		var oooooo = 0x01;
		var aaaaaa = predelabelize(line.jsr);
		output.push(((0x0 | zeroop) | oooooo << 4) | aaaaaa[0] << 10);
		
		if (aaaaaa.length == 2) {
		    output.push(aaaaaa[1]);
		    offset++;
                } 
		
		offset++;
	    }
	    
	    else {
		    var oooo = line[0];
		    var aaaaaa = predelabelize(line[1]);
		    var bbbbbb = predelabelize(line[2]);
		    output.push(((0x0 | oooo) | aaaaaa[0] << 4) | bbbbbb[0] << 10);
		    if (aaaaaa.length == 2) {
			output.push(aaaaaa[1]);
			offset++;
                    } 
		    if (bbbbbb.length == 2) {
			output.push(bbbbbb[1]);
			offset++;
                    } 
		    offset++;
		}
	}
	postdelabelize(output);
	return output;
    }

dat
    = _ "dat" _ data:(hex / decimal / symbol / str) _ {
    return {"data": data};
}

jsr
    = _ "jsr" _ jsr:(literal / symbol) _ {
    return {"jsr": jsr};
}

op  
    = _ instr:instr _ op1:operand _ "," _  op2:operand _ {return [instr,op1, op2];}

label
    = _ ":" sym:symbol _ {return {'label': sym};}

instr
    = "set" {return 1;}
    / "add" {return 2;}
    / "sub" {return 3;}
    / "mul" {return 4;}
    / "div" {return 5;}
    / "mod" {return 6;}
    / "shl" {return 7;}
    / "shr" {return 8;}
    / "and" {return 9;}
    / "bor" {return 10;}
    / "xor" {return 11;}
    / "ife" {return 12;}
    / "ifn" {return 13;}
    / "ifg" {return 14;}
    / "ifb" {return 15;}

operand
    = symbol / literal / address

symbol
    =   start:[a-zA-Z_] rest:[a-zA-Z0-9_]* {
	s = start + rest.join("");
	special = {"a":0,"b":1,"c":2,"x":3,"y":4,"z":5,"i":6,"j":7,
		   "pop":24,"peek":25,"push":26,
		   "sp":27,"pc":28,"o":29};
	specialv = special[s];
	console.log("symbol: " + s +", spec: " + specialv);
	if (specialv == undefined) {
	    return {"label":s};
	}
	else {
	    return [specialv];
	}
    }

literal 
    = value:(hex / decimal) {
	if (value < 32) {
	    return [value + 32];
	}
	else {
	    return [31, value];
	}
    }

address 
    = "[" _ address:(regoffset / adrliteral / adrsymbol) _ "]"

adrliteral
    = adrliteral:(hex / decimal) {
	return [30, adrliteral];
    }

adrsymbol
    = symbol:symbol {
	if (symbol.label == undefined) { // is a register
	    return [symbol[0] + 8];
	}
	else {
	    return {"symbaddr":symbol};
	}
    }

regoffset
    = offsetliteral:(hex / decimal) _ "+" _ register:symbol {
	console.log("reg off addr: " , offsetliteral, "+", register);
	return [register[0] + 16, offsetliteral];
    }

hex 
    = "0x" value:hexdigits {
	return value;
    }

decimal
    = value:decimaldigits { 
	return value;
    }


hexdigits 
    = hexdigits:[0-9a-fA-F]+ {
	return parseInt(hexdigits.join(""), 16); 
    }

decimaldigits
    = digits:[0-9]+ { 
	return parseInt(digits.join(""), 10); 
    }



str
    = "\"" str:[^\"]* "\"" {
        return {"str": str.join("")};
    }   

_ "whitespace"
  = whitespace*

whitespace
  = [ \t\n\r]