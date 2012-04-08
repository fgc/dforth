/*
* REGISTERS:
* a = accumulator
* j = stack frame pointer
* x = allocation pointer
*/

{
    var letbindings=[];
    var env=[];
    var labelid = 0;
    function getlabelid() {
	return labelid++;
    }
}

dscheme
    = result:(immediate / letexp / ifexp / primcall) {
	r = "set x, heapstart\n";
	r += "add x, 7\n"
	r += "and x, 0xF8\n"
	r += result;
	r += ":heapstart\n";
	return r;
    }

immediate
    = result:(integer / bool / empty_list / varsub) {
	return result;
    }

integer
    = digits:[0-9]+ {
	var i = parseInt(digits.join(""), 10) << 2;
	return "set a, " + i + "\n";
    }

bool
    = bool:("#t" / "#f") { 
	var b = (((bool == "#t"?1:0) << 7) | 0x1F);
 	return "set a, " + b + "\n";
    }

empty_list
    = "()" {return "set a, " + 0x2F + "\n";}

primcall
    = "(" _ op:primcall_op _ op1:primcall_operand oprest:(_ primcall_operand)* ")" {
	if (op == "add1") {
	    return op1 + "add a, " + (1 << 2) + "\n";
	}
	if (op == "sub1") {
	    return op1 + "sub a, " + (1 << 2) + "\n";
	}
	if (op == "zero?") {
	    op1 += "set b, 31\n";
	    op1 += "ife a, 0\n";
	    op1 += "set b, 159\n";
	    op1 += "set a, b\n";

	    return op1
	}
	if (op == "null?") {
	    op1 += "set b, 31\n";
	    op1 += "ife a, 0x2F\n";
	    op1 += "set b, 159\n";
	    op1 += "set a, b\n";

	    return op1;	    
	}
	if (op == "+") {
            var rest = "";
            for (i = oprest.length - 1; i > -1; i--) {
		rest += oprest[i][1];
		rest += "set push, a\n";
		op1 += "add a, pop\n";
	    }
	    return rest + op1;
	}

	if (op == "cons") {
	    r = oprest[0][1]; //compute the cdr
	    r += "set push, a\n"; //keep it
	    r += op1; //compute the car
	    r += "set [x], a\n"; //store the car
	    r += "set [1 + x], pop\n"; //store the cdr
	    r += "set a, x\n"; //return the address to this cons
	    r += "bor a, 1\n"; //tagged as a cons
	    r += "add x, 8\n"; //align to 8 words
	    return r;
	}
	
	if (op == "car") {
	    op1 += "sub a, 1\n";
	    op1 += "set a, [a]\n";
	    return op1;
	}

	if (op == "cdr") {
	    op1 += "set a, [a]\n";
	    return op1;
	}
    }

primcall_operand
    = (immediate / primcall / letexp)

primcall_op
    = "add1" / "sub1" / "zero?" / "null?" / "+" / "cons" / "car" / "cdr"

letexp
    = "(" _ letstart   bindings:bindings _ body:body _")" {
	var e = env.pop();
	var r = "set push, j\n";
	r += "set j, sp\n";
	r += bindings + body;
	r += "set sp, j\n";
	r += "set j, pop\n";
	return r;
    }

letstart
    = _ "let" _ {
	env.push({si:1});
    }

bindings
    = "(" _ bindings:(binding _)* ")" {
	var r = "";
	for(i in bindings) {
    	    r += bindings[i][0];
    	}   	
	return r;
    }

binding
    = ("(" _ symbol:symbol _ body:body _ ")") {
	e = env[env.length - 1];
	e[symbol] = e.si++;
	console.log("body from binding:",body);
	return body + "set push, a\n";
}

symbol
    = symbol:([a-z_]+[a-zA-Z_\-\*]*) { return symbol.join(""); }

varsub
    = varsub:([a-z_]+[a-zA-Z_\-\*]*) { 
	v = varsub.join("");
	e = env[env.length - 1];
	
	return "set i ,j\n sub i, " + e[v] + "\nset a ,[i]\n";
    }

body
    = immediate / letexp / ifexp / primcall

ifexp
    = "(" _ "if" _ test:body _ conseq:body _ alter:body _")" {
	var labelroot = "iflbl" + getlabelid();
	r = test;
	r += "ife a, 31\n";
	r += "set pc, " + labelroot + "alter\n";
	r += conseq;
	r += "set pc, " + labelroot + "end\n";
	r += ":" + labelroot + "alter\n";
	r += alter;
	r += ":" + labelroot + "end\n";
	return r;
    }
	

_ "whitespace"
  = whitespace*

whitespace
  = [ \t\n\r]