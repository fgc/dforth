	;; Forth implementation based on jonesforth for Notch's dcpu
	
	;; esi -> i source
	;; eax -> a accumulator
	;; ebp -> z return stack
	
	.macro NEXT 		;jump to the address stored at the location pointed to by i
	set a, (i)
	add i, 1
	set PC, a
	.endm

	.macro PUSHRSP reg
	set z, (z - 1)		;jf is 4 here, think about why
	set (z), reg
	.endm

	.macro POPRSP reg
	set reg, (z)
	set z, (z + 1)		;jf is 4 here, think about why	
	.endm
