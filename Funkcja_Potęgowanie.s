.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3

.equ RESULT, 16384
.equ ARGUMENTS, 8192

.section .bss

.lcomm argument, ARGUMENTS
.lcomm argumentCurrentValue, 4
.lcomm argumentSize1, 4
.lcomm argumentSize2, 4
.lcomm argumentSize3, 4

.lcomm exponent, ARGUMENTS
.lcomm binaryExponent, ARGUMENTS
.lcomm binaryExponentSize, 4

.lcomm currentPower1, RESULT
.lcomm currentPower2, RESULT
.lcomm currentPowerSize1, 4
.lcomm currentPowerSize2, 4

.lcomm currentResult1, RESULT
.lcomm currentResult2, RESULT
.lcomm finalResult, RESULT
.lcomm finalResultSize, 4

.lcomm carry, 1
.lcomm finalCarry, 1

.section .data
 base: .long 10

 size: .long 1024
 currentSize: .long 0
 sizeCounter: .long 0

 binaryExponentVariable: .long 0

	info:
	.ascii "Argument to the power of Exponent\n-------------------------------\0"
	info_len = .-info

	first:
	.ascii "\nArgument: \0"
	first_len = .-first

	second:
	.ascii "Exponent: \0"
	second_len = .-second

	final:
	.ascii "\nFinal result: \0"
	final_len = .-final

.section .text
.globl powFunction
.type powFunction, @function
  powFunction:

 movl size, %eax
 movl %eax, currentSize
 xorl %eax, %eax
 movb $'1', currentResult1(,%eax,1)

infoMessage:
  movl $WRITE, %eax
  movl $STDOUT, %ebx
  movl $info, %ecx
  movl $info_len, %edx
  int $LINUX_SYSCALL

firstMessage:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $first, %ecx
	movl $first_len, %edx
	int $LINUX_SYSCALL

	movl $READ, %eax
	movl $STDIN, %ebx
	movl $argument, %ecx
	movl $ARGUMENTS, %edx
	int $LINUX_SYSCALL

	decl %eax
	decl %eax
	movl %eax, currentPowerSize1
  movl %eax, currentPowerSize2

secondMessage:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $second, %ecx
	movl $second_len, %edx
	int $LINUX_SYSCALL

	movl $READ, %eax
	movl $STDIN, %ebx
	movl $exponent, %ecx
	movl $32, %edx
	int $LINUX_SYSCALL

	decl %eax
  movl currentPowerSize1, %edx

moveBaseToCurrentPower:
 xorl %ebx, %ebx
 movb argument(,%edx,1), %bl
 movb %bl, currentPower1(,%edx,1)
 decl %edx
 cmpl $0, %edx
 jge moveBaseToCurrentPower

exponentToBinaryPart1:
 pushl base
 pushl $exponent
 call powerToBinary
 addl $8, %esp
 xorl %ecx, %ecx
 xorl %edi, %edi
 movl $2, %ecx
 movl size, %edi
 decl %edi
 movl $0, binaryExponentSize

exponentToBinaryPart2:
 xorl %edx, %edx
 idiv %ecx
 addl $48, %edx
 movb %dl, binaryExponent(,%edi,1)
 decl %edi
 incl binaryExponentSize
 cmpl $0, %eax
 jne exponentToBinaryPart2

checkMultiplicationCondition:
 xorl %ebx, %ebx
 movl size, %edi
 decl %edi
 movl binaryExponentSize, %eax
 subl binaryExponentVariable, %edi
 incl binaryExponentVariable
 cmpl %eax, binaryExponentVariable
 jg showFinalResult
 movb binaryExponent(,%edi,1), %bl
 cmpl $'0', %ebx
 je getPower

 pushl finalResultSize
 pushl $currentPower1
 pushl $currentResult1
 pushl currentPowerSize1
 call multiplication
 popl currentPowerSize1
 addl $12, %esp

 xorl %eax, %eax
 movl currentPowerSize1, %eax

 pushl $finalResult
 pushl $currentResult1
 call copyString
 addl $8, %esp

 pushl $currentResult1
 call findInitialZeros
 addl $4, %esp
 movl %eax, finalResultSize

 xorl %eax, %eax
 movl size, %edi
 decl %edi

prepareCurrentResultPart1:
 movb $0, finalResult(,%edi,1)
 decl %edi
 cmpl $0, %edi
 jge prepareCurrentResultPart1

getPower:
 movl binaryExponentSize, %eax
 movl binaryExponentVariable, %ebx
 cmpl %eax, binaryExponentVariable
 je showFinalResult

 pushl $currentPower1
 pushl $currentPower2
 call copyString
 addl $8, %esp

 pushl currentPowerSize2
 pushl $currentPower1
 pushl $currentPower2
 pushl currentPowerSize1
 call multiplication
 addl $16, %esp

 pushl $finalResult
 pushl $currentPower1
 call copyString
 addl $8, %esp

 pushl $currentPower1
 call findInitialZeros
 addl $4, %esp
 movl %eax, currentPowerSize1

 movl currentPowerSize1, %eax
 movl %eax, currentPowerSize2

 xorl %eax, %eax
 movl size, %edi
 decl %edi

prepareCurrentResultPart2:
 movb $0, finalResult(,%edi,1)
 decl %edi
 cmpl $0, %edi
 jge prepareCurrentResultPart2
 jmp checkMultiplicationCondition

showFinalResult:
  movl finalResultSize, %eax
  incl %eax
  movb $0xA, currentResult1(,%eax,1)

  movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $final, %ecx
	movl $final_len, %edx
	int $LINUX_SYSCALL

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $currentResult1, %ecx
	movl $RESULT, %edx
  int $LINUX_SYSCALL

end:
  movl $EXIT, %eax
  movl $0, %ebx
  int $LINUX_SYSCALL

.type charToInt,@function
charToInt:
	pushl %ebp
	movl %esp, %ebp

	xorl %ebx, %ebx
	movl 8(%ebp), %ebx
	subb $0x30, %bl
	cmpb $10, %bl
	jb charToIntEnd

charToIntEnd:
	movl %ebx, %eax
	movl %ebp, %esp
	popl %ebp
	ret

.type intToChar,@function
intToChar:
	pushl %ebp
	movl %esp, %ebp

	movl 8(%ebp), %eax
	addb $0x30, %al
	cmpb $0x39, %al
	movl %ebp, %esp
	popl %ebp
	ret

.type addToFinalResult,@function
addToFinalResult:
 pushl %ebp
 movl %esp, %ebp
 xorl %edx, %edx
 movl size, %edx
 decl %edx

step1:
 xorl %ebx, %ebx
 movb currentResult2(,%edx,1), %bl
 movb finalResult(,%edx,1), %al
 addl %ebx, %eax
 addl finalCarry, %eax
 movl $0, finalCarry
 cmpl base, %eax
 jl step2

 xorl %ecx, %ecx
 subl base, %eax
 incl %ecx
 movl %ecx, finalCarry

step2:
 cmpl $0, argumentSize1
 jl step4

step3:
 movb %al, finalResult(,%edx,1)
 decl %edx
 cmpl $0, %edx
 jge step1
 jmp finalStep

step4:
 pushl %eax
 call intToChar
 addl $4, %esp
 movb %al, finalResult(,%edx,1)
 decl %edx
 cmpl $0, %edx
 jge step1

finalStep:
 movl %ebp, %esp
 popl %ebp
 ret

.type findInitialZeros,@function
findInitialZeros:
 pushl %ebp
 movl %esp, %ebp

 xorl %eax, %eax
 xorl %ecx, %ecx
 movl size, %eax
 movl %eax, sizeCounter
 xorl %eax, %eax
 xorl %edi, %edi

findInitialZerosBegin:
 incl %edi
 movl 8(%ebp), %ecx
 movl $0, %edx
 decl sizeCounter
 movb (%ecx), %al
 incl %ecx
 incl %edx
 cmpl $'0', %eax
 jne findInitialZerosEnd

deleteInitialZeros:
 xorl %eax, %eax
 movb (%ecx), %al
 decl %edx
 decl %ecx
 movb %al, (%ecx)
 addl $2, %edx
 addl $2, %ecx
 cmpl sizeCounter, %edx
 jle deleteInitialZeros
 decl %ecx
 movl $0, (%ecx)
 jmp findInitialZerosBegin

findInitialZerosEnd:
 xorl %eax, %eax
 movl size, %eax
 subl %edi, %eax
 movl %ebp, %esp
 popl %ebp
 ret

.type multiplication, @function
multiplication:
 pushl %ebp
 movl %esp, %ebp
 xorl %eax, %eax
 xorl %ebx, %ebx
 movl 20(%ebp), %eax
 movl 8(%ebp), %ebx
 movl %eax, argumentSize1
 movl %ebx, argumentSize3

checkCondition:
 cmpl $0, argumentSize1
 jl FinalResultLabel
 xorl %edi, %edi
 movl size, %edi
 decl %edi
 xorl %ecx, %ecx
 movl size, %ecx
 subl currentSize, %ecx
 decl currentSize

main:
 cmpl $0, %ecx
 jle firstToInt
 movb $0, currentResult2(,%edi,1)
 decl %edi
 decl %ecx
 jmp main

firstToInt:
 xorl %ecx, %ecx
 xorl %edx, %edx
 movl 12(%ebp), %ecx

 movl $0, argumentCurrentValue
 movl argumentSize1, %edx
 addl %edx, %ecx
 cmpl $0, %edx
 jl firstToIntEnd
 xorl %ebx, %ebx
 decl argumentSize1
 movb (%ecx), %bl
 xorl %ecx, %ecx

 pushl %ebx
 call charToInt
 addl $4, %esp
 movl %eax, argumentCurrentValue
 movl argumentSize3, %edx
 movl %edx, argumentSize2
 jmp secondToInt

firstToIntEnd:
 xorl %eax, %eax
 jmp FinalResultLabel

secondToInt:
 movl 16(%ebp), %ecx
 xorl %eax, %eax
 movl argumentSize2, %edx
 addl %edx, %ecx
 cmpl $0, %edx
 jl secondToIntEnd
 decl argumentSize2
 movb (%ecx), %bl
 xorl %ecx, %ecx

 pushl %ebx
 call charToInt
 addl $4, %esp
 jmp multiplicationLabel

secondToIntEnd:
 cmpl $0, argumentSize1
 jge multiplicationLabel
 cmpl $0, argumentSize2
 jge multiplicationLabel
 cmpl $0, carry
 jg multiplicationLabel
 jmp completePartialProduct

multiplicationLabel:
 xorl %ecx, %ecx
 imull argumentCurrentValue, %eax
 addl carry, %eax
 movb $0, carry

checkConditionBase:
 cmpl base, %eax
 jb createPartialProduct
 subl base, %eax
 incl %ecx
 jmp checkConditionBase

createPartialProduct:
 movl %ecx, carry
 movb %al, currentResult2(,%edi,1)
 decl %edi
 xorl %ecx, %ecx
 movl argumentSize2, %ecx
 cmpl $0, %ecx
 jge secondToInt
 xorl %ecx, %ecx
 movl carry, %ecx
 cmpl $0, %ecx
 jne secondToInt

completePartialProduct:
 decl %edi
 cmpl $0, %edi
 jl createFinalResult
 movb $0, currentResult2(,%edi,1)
 jmp completePartialProduct

createFinalResult:
 call addToFinalResult
 jmp checkCondition

FinalResultLabel:
 movl size, %eax
 movl %eax, currentSize
 movl %ebp, %esp
 popl %ebp
 ret

.type copyString, @function
copyString: //
 pushl %ebp
 movl %esp, %ebp
 xorl %edi, %edi
 xorl %ecx, %ecx
 xorl %edx, %edx
 movl 8(%ebp), %ecx
 movl 12(%ebp), %edx

copyStringPart1:
 movb (%edx), %bl
 movb %bl, (%ecx)
 incl %ecx
 incl %edx
 incl %edi
 cmpl size, %edi
 jl copyStringPart1

copyStringPart2:
 movl %ebp, %esp
 popl %ebp
 ret

.type powerToBinary, @function
powerToBinary:
 pushl %ebp
 movl %esp, %ebp
 movl $0, %eax
 movl 8(%ebp), %ecx
 xorl %ebx, %ebx
 movb (%ecx), %bl
 cmpb $0x20, %bl

powerToBinaryPart1:
 xorl %edx, %edx
 movl %eax, %edx
 pushl %ebx
 call charToInt
 addl $4, %esp
 movl %eax, %ebx
 xorl %eax, %eax
 movl %edx, %eax
 addl %ebx, %eax
 incl %ecx
 xorl %ebx, %ebx
 movb (%ecx), %bl

 cmpb $0x20, %bl
 jbe powerToBinaryPart2
 imull 12(%ebp), %eax
 jmp powerToBinaryPart1

powerToBinaryPart2:
 movl %ebp, %esp
 popl %ebp
 ret
