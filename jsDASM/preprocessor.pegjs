{
    macros = {};
}
dasm
    = lines:( op2 / op1 / label / defmacro / macrocall)+ {
	return lines.join("");
    }

op2
    = _ instr:instr2 _ op1:operand _ "," _ op2:operand _ {return instr + " " + op1 + ", " + op2 + "\n"}

op1
    = _ instr:instr1 _ op:operand _ {return instr + " " + op + "\n";}

label
    = _ ":" symbol:symbol _ { console.log("label",symbol); return ":" + symbol + "\n";}

braced
    = "{" parts:(braced / nonBraceCharacter)* "}" {
	return parts.join("");
    }

nonBraceCharacter
  = [^{}]

bracketed
    = "[" parts:(braced / nonBracketCharacter)* "]" {
	return parts.join("");
    }

nonBracketCharacter
    = [^\[\]]

defmacro 
    = _ "#defmacro" _ name:symbol _ "(" _ paramlist:(symbol _)* ")"_  body:braced  _ env:bracketed? _ {
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
	    macrodef += env;
	}
	macrodef += "macros[\"" + name + "\"] = function (" + paramstr + ") {";
	macrodef += body
	macrodef += "}";
        console.log("macrodef:",macrodef);
        console.log("env:",env);
	eval(macrodef);
	return "";
}

macrobody
    = macrobody:[^\]]* { return macrobody.join(""); }


macrocall
    = _ name:symbol _ "("_ params:[^\)]* _")" _ {
	
	return eval ("macros[\"" + name + "\"](" + params.join("")+")");
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
    / "[" _ literal:literal _ "]" {return "[" + literal + "]";}
    / "[" _ symbol:symbol _ "]" {return "[" + symbol + "]";}

literal
    = digits:[0-9A-Fa-fx]+ {return digits.join("");}
/*
_ "whitespace"
  = whitespace*

whitespace
  = [ \t\n\r]
*/

_ 
  = ( whiteSpace / lineTerminator / lineComment )* 
whiteSpace 
  = [\t\v\f \u00A0\uFEFF] 
lineTerminator 
  = [\n\r] 
lineComment 
  = ";" (!lineTerminator anyCharacter)* 
anyCharacter 
  = . 