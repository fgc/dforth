{
    macros = {};
}
dasm
    = lines:(op2 / op1 / label / defmacro / macrocall)+ {
	return lines.join("");
    }

op2
    = _ instr:instr2 _ op1:operand _ "," _ op2:operand _ {return instr + " " + op1 + ", " + op2 + "\n"}

op1
    = _ instr:instr1 _ op:operand _ {return instr + " " + op + "\n";}

label
    = _ ":" symbol:symbol op:(op2 / op1)? _ { console.log("label",symbol);return ":" + symbol + " " + op;}

defmacro 
    = _ "#defmacro" _ name:symbol _ "(" _ paramlist:(symbol _)* ")"_ "[" _ body:macrobody _ "]" _ env:("[" _ macrobody _ "]")? _ {
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
	    macrodef += env[2];
	}
	macrodef += "macros[\"" + name + "\"] = function (" + paramstr + ") {";
	macrodef += body
	macrodef += "}";
        console.log("macrodef:",macrodef);
	eval(macrodef);
	return "";
}

macrobody
    = macrobody:[^\]]* { return macrobody.join(""); }


macrocall
    = _ name:symbol _ "("_ params:[^\)]* _")" _ {
	return macros[name]();
    }

instr2
    = "set"
    / "add"
    / "sub"
    / "mul"
    / "div"
    / "mod"
    / "shl"
    / "shr"
    / "and"
    / "bor"
    / "xor"
    / "ife"
    / "ifn"
    / "ifg"
    / "ifb"

instr1
    = "dat" / "jsr"

symbol
    =   first:[a-zA-Z_] rest:[a-zA-Z0-9_]* { return first + rest.join("");}

operand
    = symbol / literal / address

address
    = "[" _ literal:literal _ "+" _ symbol:symbol _ "]" {return "[" + literal + " + " + symbol + "]";}
    / "[" _ unary:(literal / symbol) _ "]" {return "[" + unary + "]";}

literal
    = digits:[0-9A-Fa-fx]+ {return digits.join("");}

_ "whitespace"
  = whitespace*

whitespace
  = [ \t\n\r]