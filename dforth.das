	;; Forth implementation based on jonesforth for Notch's dcpu
	
	;; special reguisters:
	;; i source
	;; z return stack pointer

	;; let's assume we can do macros, we can preproccess them later if not
	
	macro NEXT 		;jump to the address stored at the location pointed to by i
	set a, (i)
	add i, 2
	set PC, a
	endmacro

	macro PUSHRSP reg
	set z, (z - 2)
	set (z), \reg
	endmacro

	macro POPRSP reg
	set \reg, (z)
	set z, (z + 2)
	endmacro

DOCOL:
	PUSHRSP i		;push i on to the return stack
	add a,1			;a points to the codeword
	set i,a			;now i points to the first data word
	NEXT

_start:
	set (var_S0), sp	;save the initial data stack pointer
	set z, rsp		;set initial return stack
	set i, cold_start	;initialize interpreter
	NEXT			;go!
cold_start:
	wdat QUIT


	let link, 0


	macro defword name, namelen, flags=0, label
name_\label:
	wdat link
	let link, name_\label
	dat \flags+\namelen
	dat "\name"
\label:
	wdat DOCOL
	endmacro

	macro defcode name, namelen, flags=0, label
name_\label:
	wdat link
	let link, name_\label
	dat \flags+\namelen
	dat "\name"
\label:
	dat code_\label
code_\label:
	endmacro

	defcode "DROP",4,0,DROP
	pop a		;drop top of stack
	NEXT

	defcode "SWAP",4,0,SWAP
	pop a		;drop top of stack
	pop b		;and the next value too
	push a			;now the first is the second
	push b			;and the second is first
	NEXT

	defcode "DUP",3,0,DUP
	set a, (sp)		;duplicate top of stack
	push a

	defcode "OVER",4,0,OVER
	set a, (sp + 2)		;copy the second element of the stack
	push a			;on top
	NEXT

	defcode "ROT",3,,ROT
	pop a
	pop b
	pop c
	push b
	push a
	push c
	NEXT

	defcode "-ROT",4,,NROT
	pop a
	pop b
	pop c
	push a
	push c
	push b
	NEXT

	defcode "2DROP",5,0,TWODROP
	pop a
	pop a
	NEXT

	defcode "2DUP",4,0,TWODUP
	set a,(sp)
	set b,(sp + 2)
	push b
	push a
	NEXT

	defcode "2SWAP",5,0,TWOSWAP
	pop a
	pop b
	pop c
	pop d
	push b
	push a
	push d
	push c
	NEXT

	defcode "?DUP",4,0,QDUP
	set a, (sp)
	ifn a, 0
	push a
	NEXT

	defcode "1+",2,0,INCR
	add (sp),1
	NEXT

	defcode "1-",2,0,DECR
	sub (sp),1
	NEXT

	defcode "2+",2,0,INCR2
	add (sp),2
	NEXT

	defcode "2-",2,0,DECR2
	sub (sp),2
	NEXT

	defcode "+",1,0,ADD
	pop a
	add (sp), a
	NEXT
	
	defcode "-",1,0,SUB
	pop a
	sub (sp), a
	NEXT
	
	defcode "*",1,0,MUL
	pop a
	pop b
	mul a, b
	push a
	NEXT

	;; TODO comparisons and bitwise stuff

	defcode "EXIT",4,0,EXIT
	POPRSP i
	NEXT

	defcode "LIT",3,0,LIT
	set a,(i)
	add i, 2
	push a
	NEXT

	;; TODO memory management stuff

	macro defvar name,namelen,flags,label,initial
	defcode \name,\namelen,\flags,\label
	push var_\name
	NEXT
var_\name:
	wdat initial
	endmacro

	defvar "STATE",5,0,STATE,0
	defvar "HERE",4,0,HERE,0
	defvar "LATEST",6,0,LATEST,name_SYSCALL0 // SYSCALL0 must be last in built-in dictionary
	defvar "S0",2,0,SZ,0
	defvar "BASE",4,0,BASE,10

	;; TODO built in constants




rsp:
	dat 0
