
.data

# CONSOLE PROMPT DECLARATIONS  
infix:			.space 256
postfix:		.space 256
stack: 			.space 256
prompt1:    	.asciiz "Enter a fully parenthesized expression to be evaluated:\n"
prompt2:		.asciiz "Infix expression to be evaluated: "
prompt3: 		.asciiz "Postfix expression: "
prompt4:		.asciiz "Result: "
endingMSG:		.asciiz "Program ended."
newLine:		.asciiz "\n"

# REGISTER NOTES:
# $s0 = address of infix expression
# $s1 = address of postfix expression
# $s2 = '+' operator
# $s3 = '-' operator
# $s4 = '('
# $s5 = ')'
# $t0 = num parenthesis counter
# $t1 = byte currently being evaluated in the infix expression
# $t2 = element counter for postfix expression
# $t3 = byte currently being evaluated in the postfix expression
	
	.globl main 
	.text 		

# The label 'main' represents the starting point
main:

# 4 PARTS:
# 	1: INPUT
#	2: CONVERT TO POSTFIX
#	3: EVALUATE
#	4: OUTPUT
################################ 1 #######################################
#############################TAKE INPUT###################################
##########################################################################

promptForInput:

# display prompt message
	li		$v0, 54				# syscall code for InputDialogString
	la		$a0, prompt1		# point $a0 to prompt1 asking for expression
	la		$a1, infix			# set the address of the input buffer
	la		$a2, 256			# set the size of the input for the dialog box to 256
	syscall						# show the dialog box

# Print user entered infix string 
	li 		$v0, 4				# syscall code for print_string
	la 		$a0, prompt2		# point $a0 to prompt2 displaying "infix expression:"
	syscall						# display the message
	
	li 		$v0, 4				# syscall code for print_string
	la 		$a0, infix			# point $a0 to infix, the location of the user entered expression
	syscall						# display the infix expression


################################ 2 #######################################
#########################CONVERT TO POSTFIX###############################
##########################################################################

# register setup
	la		$s0, infix			# point $s0 to infix memory address
	la		$s1, postfix		# point $s1 to postfix memory address
	li 		$s2, '+'			# set register $s2 to be '+'
    li 		$s3, '-'			# set register $s3 to be '-'
    li 		$s4, '('			# set register $s4 to be '('
    li 		$s5, ')'			# set register $s2 to be ')'
	addi	$t0, $zero, 0		# set parenthesis counter to 0
	addi	$t2, $zero, 0		# set postfix counter to 0
	
	addi	$s0, $s0, -1		# set $s0 to -1 initially for infix byte counter
	addi	$s1, $s1, -1		# set $s1 to -1 initially for postfix byte counter
	
	
scanInfix:
	addi	$s0, $s0, 1			# increment byte counter by 1
	lbu		$t1, ($s0)			# load the element at the current byte
	beq		$t1, ' ', scanInfix	# if the current byte is a space, skip it
	beq 	$t1, '\n', evalExp	# if the current byte is the new line character, indicates end of line. end the program.

# else if the current byte is not a space or '\n', it must be a digit, operator, or parenthesis:

	jal 	postfixLogic
	j		scanInfix


################################ 3 #######################################
########################EVALUATE EXPRESSION###############################
##########################################################################
evalExp:
	
# register setup
	la		$s1, postfix		# point $s1 to postfix memory address
	addi	$s1, $s1, -1		# set $s1 to -1 initially for postfix byte counter
	
scanPostfix:

	beqz 	$t2, endProg		# if the current byte is the new line character, indicates end of line. end the program.
	addi	$s1, $s1, 1			# increment byte counter by 1
	lbu		$t1, 0($s1)			# load the element at the current byte	
	addi 	$t2, $t2, -1		# decrement element counter
	
	
	jal		evaluateLogic		# jump and link to evaluateLogic
	j		scanPostfix			# repeat the process


################################ 4 #######################################
###############################OUTPUT#####################################
##########################################################################

# end the program
endProg:

	
	li 		$v0, 4				# syscall code for print_string
	la 		$a0, postfix		# point $a0 to postfix, the converted expression
	syscall						# display the postfix expression
	
	addi 	$a0, $zero, 61		# ASCII value for '='
	addi 	$v0, $zero, 11		# set $v0 to 11 to print char
	syscall						# print '='
	
	lw		$t1, 0($sp)			# load the current byte from the stack into $t9

	move	$a0, $t1
	addi 	$v0, $zero, 1		# set $v0 to 1 (print integer)
	syscall						# print expression result from top of stack
	
	li		$v0, 4				# syscall code for print_string
	la		$a0, newLine		# point $a0 to print a new line
	syscall	
	
 	li		$v0, 4				# syscall code for print string
 	la		$a0, endingMSG		# display ending message
 	syscall
	
 	li		$v0, 10				# syscall exit
 	syscall
	
##########################################################################	
############################ postfixLogic ################################
# logic dealing with each type of input
postfixLogic:
	beq 	$t1, $s2, operator	# current byte is '+', branch to operator logic
	beq 	$t1, $s3, operator	# current byte is '-', branch to operator logic
	beq		$t1, $s4, lPar		# current byte is '(', branch to parenthesis logic
	beq		$t1, $s5, rPar		# current byte is ')', branch to parenthesis logic
	
# hitting this point means that the current byte being evaluated is a number and should be added to the postfix expression
	addi	$s1, $s1, 1			# increment the address pointer by 1
	sb		$t1, 0($s1)			# store the number in postfix expression
	addi 	$t2, $t2, 1			# increment element counter by 1
	jr		$ra					# return to line 93


# if a left parenthesis is encountered, push it to the stack	
lPar:
	addi 	$sp, $sp, -4		# move stack pointer down one
	sb 		$t1, 0($sp)			# store the left parenthesis on the stack
	addi	$t0, $t0, 1			# increment parenthesis counter
	jr		$ra					# return to line 93


# if a right parenthesis is encountered, pop from the stack, addu to postfix expression until left parenthesis is encountered
rPar:
	
	lbu		$t9, 0($sp)			# load the current byte from the stack into $t9
	addi	$sp, $sp, 4			# move the stack pointer up one
	
	bne		$t9, $s4, contRPar	# if the current byte is not a right parenthesis, pop again
	beq		$t9, $s4, leaveRPar	# if the current byte is a right parenthesis, leave the loop
	
contRPar:
	addi 	$s1, $s1, 1			# increment the address pointer by 1
	sb		$t9, 0($s1)			# store the current byte in postfix expression
	addi 	$t2, $t2, 1			# increment element counter by 1
	beq		$zero, $zero, rPar	# jump to rPar and pop again
	
leaveRPar:
	addi 	$t0, $t0, -1		# decrement parenthesis counter
	jr		$ra					# return to line 93


# if an operator has been scanned, check if the top stack element is an operator (pop if so), otherwise push to stack	
operator:
	lbu		$t9, 0($sp)			# load the element at the top of the stack to $t9
	beq		$t9, $s4, toStack	# if the top of stack is the open parenthesis, push the operator to stack
	
opPop:
	addi	$sp, $sp, 4			# move the stack pointer up one
	addi 	$s1, $s1, 1			# increment the address pointer by 1
	sb		$t9, 0($s1)			# store the current byte in postfix expression
	addi 	$t2, $t2, 1			# increment element counter by 1
	
	lbu		$t9, 0($sp)			# load the next element from the stack to $t9
	bne		$t9, $s4, opPop		# if the next element is not '(', continue to pop, else continute to toStack
	
toStack:
	addi 	$sp, $sp, -4		# move stack pointer down one
	sb 		$t1, 0($sp)			# store the operator on the stack
	jr		$ra					# return to line 93
	
############################ postfixLogic ################################

########################### evaluateLogic ################################

evaluateLogic:

	beq 	$t1, $s2, evalPlus	# current byte is '+', branch to evalPlus logic
	beq 	$t1, $s3, evalMin	# current byte is '-', branch to evalMin logic

# else, the current byte is a number, push to stack
	addi 	$sp, $sp, -4		# move stack pointer down one
	addi	$t1, $t1, -48

	sw 		$t1, 0($sp)			# store the operator on the stack
	jr		$ra					# return to line 112
	
evalPlus:
	lw		$t7, 0($sp)			# store the current byte in $t7 indicating the right operand

	addi	$sp, $sp, 4			# move the stack pointer up one
	lw		$t6, 0($sp)			# store the current byte in $t6 indicating the left operand
	
	add		$t1, $t6, $t7		# addu the values in $t6 and $t7, store the result in $t1
	
	sw 		$t1, 0($sp)			# store the result on the stack
	jr		$ra					# return to line 112
	
evalMin:
	lw		$t7, 0($sp)			# store the current byte in $t7 indicating the right operand
	
	addi	$sp, $sp, 4			# move the stack pointer up one
	lw		$t6, 0($sp)			# store the current byte in $t6 indicating the left operand
	
	sub		$t1, $t6, $t7		# subtract the values in $t6 and $t7, store the result in $t1

	sw 		$t1, 0($sp)			# store the result on the stack
	jr		$ra					# return to line 112
	
########################### evaluateLogic ################################