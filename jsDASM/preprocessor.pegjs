{
    macros = {};
}
dasm
    = lines:( op2 / op1 / dat / label / defmacro / macrocall)+ {
	return lines.join("");
    }

op2
    = _ instr:instr2 _ op1:operand _ op2:operand _ {return instr.toLowerCase() + " " + op1 + ", " + op2 + "\n"}

op1
    = _ instr:instr1 _ op:operand _ {return instr.toLowerCase() + " " + op + "\n";}

label
    = _ ":" identifier:identifier _ { console.log("label",identifier); return ":" + identifier + "\n";}

braced
    = "{" parts:(braced / nonbracecharacter)* "}" {
	return parts.join("");
    }

nonbracecharacter
  = [^{}]

bracketed
    = "[" parts:(braced / nonbracketcharacter)* "]" {
	return parts.join("");
    }

nonbracketcharacter
    = [^\[\]]

defmacro 
    = _ "#defmacro" _ name:identifier _ "(" _ paramlist:(identifier _)* ")"_  body:braced  _ env:bracketed? _ {
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
    = _ name:identifier _ "("_ params:[^\)]* _")" _ {
	
	return eval ("macros[\"" + name + "\"](" + params.join("")+")");
    }

instr2
    = instr2:("set" / "SET"
	      / "add" / "ADD"
	      / "sub" / "SUB"
	      / "mul" / "MUL"
	      / "div" / "DIV"
	      / "mod" / "MOD"
	      / "shl" / "SHL"
	      / "shr" / "SHR"
	      / "and" / "AND"
	      / "bor" / "BOR"
	      / "xor" / "XOR"
	      / "ife" / "IFE"
	      / "ifn" / "IFN"
	      / "ifg" / "IFG"
	      / "ifb" / "IFB") !identifierchar { return instr2; }

instr1
    = instr1:("jsr" / "JSR") !identifierchar { return instr1; }

dat = ("dat" /  "DAT") !identifierchar _ first:(literal / identifier / str) _ rest:((literal / identifier / str) _)* {
    var r = "dat " + first + "\n";
    for (d in rest) {
	r += "dat " + rest[d][0] + "\n";
    }
    return r;
}

reserved
    = register / instr1 / instr2 / dat / keyword

register
    = register:("a" / "A"
    /"b" / "B"
    /"c" / "C"
    /"x" / "X"
    /"y" / "Y"
    /"z" / "Z"
    /"i" / "I"
    /"j" / "J") !identifierchar { 
	console.log("Found register:",register); 
	return register.toLowerCase(); 
    }

keyword
    = keyword:("sp" / "SP"
    /"pc" / "PC"
    /"push" / "PUSH"
    /"pop" / "POP"
    /"peek" / "PEEK") !identifierchar { 
	console.log("Found keyword:",keyword); 
	return keyword.toLowerCase(); 
    }

identifier
    =  !reserved identifier:identifiername { return identifier;}

identifiername
    = first:identifierfirstchar rest:identifierchar* {
	return first + rest.join("");
    }

identifierfirstchar
    = [a-zA-Z_]

identifierchar
    = [a-zA-Z0-9_]

operand
    = register/ keyword / identifier / literal / address

address
    = "[" _ literal:literal _ "+" _ register:register _ "]" {return "[" + literal + " + " + register + "]";}
    / "[" _ register:register _ "+" _ literal:literal _ "]" {return "[" + literal + " + " + register + "]";}
    / "[" _ identifier:identifier _ "+" _ register:register _ "]" {return "[" + identifier + " + " + register + "]";}
    / "[" _ register:register _ "+" _ identifier:identifier _ "]" {return "[" + identifier + " + " + register + "]";}
    / "[" _ address:(register / identifier / literal) _ "]" {return "[" + address + "]";}

literal
    = digits:[0-9A-Fa-fx]+ {return digits.join("");}

str
    = "\"" str:(!unscapedquote anycharacter)* last:unscapedquote {
	var r = "";
	for (var c in str) {
	    r += str[c][1];
	}
	return "\"" + r + last  +"\""; 
    }

unscapedquote
    = last:[^\\] "\"" {return last;}

_ 
    = ( whitespace / lineterminator / linecomment )* 
whitespace 
    = [\t\v\f \u00A0\uFEFF,] 
lineterminator 
  = [\n\r] 
linecomment 
    = ";" comment:(!lineterminator anycharacter)*
anycharacter 
  = .