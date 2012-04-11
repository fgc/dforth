{
    var macros = {};
}
dasm
    = lines:(op / label / defmacro / macrocall)+ {
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
		if (cell.label != undefined) {
		    program[pos] = labels[cell.label];
		}
	    }
	    return program;	    
	}

	for (var i in lines) {
	    var line = lines[i];
	    console.log("line:" + JSON.stringify(line));
	    if (line.label != undefined) {
		labels[line.label.label] = offset;
	    }
	    else if (line.macrodef == undefined) {
		    var oooo = line[0];
		    var aaaaaa = predelabelize(line[1]);
		    var bbbbbb = predelabelize(line[2]);
                    console.log(JSON.stringify([]))
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

defmacro 
    = _ "#defmacro" _ name:macroname _ "(" _ paramlist:(macroname _)* ")"_ "[" _ body:macrobody _ "]" _ env:("[" _ macrobody _ "]")? _{
	console.log("macro!");
	console.log("name:", name,"params", paramlist, "body", body);
	var paramstr = "";
	for (i in paramlist) {
	    if (i > 0) {
		paramstr += ", ";
	    }
	    paramstr += paramlist[i][0];
	}
	var macrodef = "";
	if (env != undefined) {
	    macrodef += env[2] + "; ";
	}
	macrodef += "macros[name] = function (" + paramstr + ") {";
	macrodef += body
	macrodef += "}";
	eval(macrodef);
	return {macrodef: true};
}

macroname
    = first:[a-zA-Z_] rest:[a-zA-Z0-9_-]* {
	return first + rest.join("");
    }

macrobody
    = macrobody:[^\]]* {return macrobody.join("");}

macrocall
    = _ name:macroname _ "("_ paramlist:(macroname _)* ")" _ {	
	console.log("macrocall",macros[name]);
	for (i in paramlist) {
	    if (i > 0) {
		paramstr += ", ";
	    }
	    paramstr += paramlist[i][0];
	}
	expansion = macros[name]();
	lines = [];
	for (var i in expansion) {
	    lines.push(dasm.parse(expansion[i], "macroexpand"));
	}
	return lines;
    }

macroexpand
    = (op / label / macrocall)*

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
    = hex / decimal

address 
    = "[" _ literal:literal _ "]" {
	if (literal.length == 1) {
	    return [30, literal[0] - 32];
	}
	else {
	    return [30, literal[1]];
	}
    }
    / "[" _ symbol:symbol _ "]" {
	if (symbol.label == undefined) {
	    return [symbol[0] + 8];
	}
	else {
	    console.log("symbaddr: ",symbol);
	    return {"symbaddr":symbol};
	}
    }
    / "[" _ literal:literal _ "+" _ symbol:symbol _ "]" {
	console.log("reg off addr: " , literal, " ", symbol);
	var addr = 0;
	if (literal.lenght == 1) {
	    addr = literal[0] - 32;
	}
	else {
	    addr = literal[1];
	}
	if (symbol.label == undefined) {
	    return [symbol[0] + 16, addr];
	}
	else {
	    return {"error":symbol};
	}
    }

hex 
    = "0x" hexdigits:[0-9a-fA-F]+ {
	var literalint = parseInt(hexdigits.join(""), 16); 
	if (literalint < 32) {
	    return [literalint + 32];
	}
	else {
	    return [31, literalint];
	}
    }

decimal
    = digits:[0-9]+ { 
	var literalint = parseInt(digits.join(""), 10); 
	if (literalint < 32) {
	    return [literalint + 32];
	}
	else {
	    return [31, literalint];
	}
    }

_ "whitespace"
  = whitespace*

whitespace
  = [ \t\n\r]