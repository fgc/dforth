	;; Forth implementation based on jonesforth for Notch's dcpu
	
	;; esi -> i source
	;; eax -> a accumulator
	;; ebp -> z return stack
	
	macro NEXT 		;jump to the address stored at the location pointed to by i
	set a, (i)
	add i, 1
	set PC, a
	endm

	macro PUSHRSP reg
	set z, (z - 2)
	set (z), \reg
	endm

	macro POPRSP reg
	set \reg, (z)
	set z, (z + 2)
	endm

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
	endm

	macro defcode name, namelen, flags=0, label
name_\label:
	wdat link
	let link, name_\label
	dat \flags+\namelen
	dat "\name"
\label:
	dat code_\label
code_\label:
	endm
	
var_S0:
	dat 0
rsp:
	dat 0
