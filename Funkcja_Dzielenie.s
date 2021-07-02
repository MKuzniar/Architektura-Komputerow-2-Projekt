.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3

.equ ARGUMENTS, 8192
.equ RESULT, 16384

.section .bss

.lcomm argument1, ARGUMENTS
.lcomm argument2, ARGUMENTS

.lcomm argumentSize1, 4
.lcomm argumentSize2, 4
.lcomm argumentSize3, 4
.lcomm argumentSize4, 4

.lcomm finalResultSize, 4
.lcomm finalResult, RESULT

.lcomm carry, 1
.lcomm finalCarry, 1

.section .data
    base: .long 10
    size: .long 0
    sizeCounter: .long 0
    sizeFinalResult: .long 1024
    lengthResult: .long 0

	info:
	.ascii "Division of two decimal numbers\n-------------------------------\0"
	info_len = .-info

	first:
	.ascii "\nFirst argument: \0"
	first_len = .-first

	second:
	.ascii "Second argument: \0"
	second_len = .-second

	finalFirst:
	.ascii "\nFinal result: \0"
	finalFirst_len = .-finalFirst

	finalSecond:
  .ascii " Remainder: \0"
  finalSecond_len = .-finalSecond

  newLine:
  .ascii " \n\0"
  new_len = .-newLine

.section .text
.globl divFunction
.type divFunction, @function
  divFunction:

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
	movl $argument1, %ecx
	movl $ARGUMENTS, %edx
	int $LINUX_SYSCALL

	decl %eax
	decl %eax
	movl %eax, argumentSize3

secondMessage:
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $second, %ecx
	movl $second_len, %edx
	int $LINUX_SYSCALL

	movl $READ, %eax
	movl $STDIN, %ebx
	movl $argument2, %ecx
	movl $ARGUMENTS, %edx
	int $LINUX_SYSCALL

	decl %eax
	decl %eax
	movl %eax, argumentSize4
  xorl %eax, %eax

fillWithZeros:
  movl $'0', finalResult(,%eax,1)
  incl %eax
  cmpl %eax, sizeFinalResult
  jg fillWithZeros

checkCondition:
  xorl %eax, %eax
  movl argumentSize3, %eax
  movl %eax, argumentSize1
  xorl %eax, %eax
  movl argumentSize4, %eax
  movl %eax, argumentSize2
  cmpl argumentSize3, %eax
  jg showFinalResult
  jl evaluateFinalResultSize
  movl $0, %edx
  movl argumentSize4, %ecx

checkConditionPart2:
  cmpl %edx, %ecx
  jge checkConditionPart3
  jmp evaluateFinalResultSize

checkConditionPart3:
  xorl %ebx, %ebx
  movb argument1(,%edx,1), %bl
  pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
  movb argument2(,%edx,1), %bl
  pushl %eax
  pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
	movl %eax, %ebx
	popl %eax
  incl %edx
  cmpl %eax, %ebx
  je checkConditionPart2
  cmpl %eax, %ebx
  jg showFinalResult

evaluateFinalResultSize:
	movb $0, carry
	movl argumentSize1, %edi
	movl %edi, finalResultSize
  movl %edi, size

firstToInt:
	movl argumentSize1, %edx
	cmpl $0, %edx
	jl firstToIntEnd
	xorl %ebx, %ebx
	decl argumentSize1
	movb argument1(,%edx,1), %bl

	pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
	cmpb base, %al
	jge firstMessage
	jmp secondToInt

firstToIntEnd:
	xorl %eax, %eax

secondToInt:
	xorl %ebx, %ebx
	movl argumentSize2, %edx
	cmpl $0, %edx
	jl secondToIntEnd
	decl argumentSize2
	movb argument2(,%edx,1), %bl
	pushl %eax

	pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp
	cmpb base, %al
	jge firstMessage

	movl %eax, %ebx
	popl %eax

secondToIntEnd:
	cmpl $0, argumentSize1
	jge subtraction
	cmpl $0, argumentSize2
	jge subtraction
	cmpl $0, %eax
	jne subtraction
	cmpl $0, %ebx
	jne subtraction
	cmpl $1, carry
	je subtraction
	jmp completeCurrentResult

subtraction:
	subl %ebx, %eax
	subl carry, %eax
	movb $0, carry
	cmpl $0, %eax
	jge createCurrentResult

	addl base, %eax
	movb $1, carry

createCurrentResult:
	pushl %eax
	call intToChar
	addl $4, %esp

  xorl %edx, %edx
  incl argumentSize1
  movl argumentSize1, %edx
  movb $0, argument1(,%edx,1)
	movb %al, argument1(,%edx,1)
	decl %edi
  decl argumentSize1

	jmp firstToInt

completeCurrentResult:
  call findInitialZeros
  xorl %eax, %eax
  movl $0, carry
  xorl %edx, %edx
  movl sizeFinalResult, %edx
  subl $1, %edx

resultToInt:
  xorl %ebx, %ebx
  movb finalResult(,%edx,1), %bl
  pushl $base
	pushl %ebx
	call charToInt
	addl $8, %esp

  xorl %ebx, %ebx
  cmpl %ebx, carry
  jg checkCarry
  addb $1, %al

checkCarry:
  addb carry, %al
  movb $0, carry

  cmpl base, %eax
  jge addCarry
  jmp completeResultToInt

addCarry:
  subb base, %al
  pushl %eax
	call intToChar
	addl $4, %esp

  movb %al,finalResult(,%edx,1)
  movl $1, carry
  decl %edx
  jmp resultToInt

completeResultToInt:
  pushl %eax
	call intToChar
	addl $4, %esp
  movb %al,finalResult(,%edx,1)
  jmp checkCondition

showFinalResult:
  movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $finalFirst, %ecx
	movl $finalFirst_len, %edx
	int $LINUX_SYSCALL

  call findInitialZerosResult
	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $finalResult, %ecx
	movl $RESULT, %edx
	int $LINUX_SYSCALL

  movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $finalSecond, %ecx
	movl $finalSecond_len, %edx
	int $LINUX_SYSCALL

	movl $WRITE, %eax
	movl $STDOUT, %ebx
	movl $argument1, %ecx
	movl $ARGUMENTS, %edx
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

.type findInitialZeros,@function
findInitialZeros:
  xorl %edx, %edx
  xorl %eax, %eax
  xorl %ecx, %ecx
  movl size, %eax
  movl %eax, sizeCounter
  addl $2, sizeCounter
  xorl %eax, %eax

findInitialZerosBegin:
  movl $0, %edx
  decl sizeCounter
  movb argument1(,%edx,1), %al
  incl %edx
  cmpl $0, argumentSize3
  je findInitialZerosEnd
  cmpl $'0', %eax
  je shorterLength
  jmp findInitialZerosEnd

shorterLength:
  decl argumentSize3

deleteInitialZeros:
  xorl %eax, %eax
  movb argument1(,%edx,1), %al
  decl %edx
  movb %al, argument1(,%edx,1)
  addl $2, %edx
  cmpl sizeCounter, %edx
  jle deleteInitialZeros

deleteRedundand:
  decl %edx
  movl $0, argument1(,%edx,1)
  jmp findInitialZerosBegin

findInitialZerosEnd:
	ret

.type findInitialZerosResult,@function
findInitialZerosResult:
  xorl %edx, %edx
  xorl %eax, %eax
  xorl %ecx, %ecx
  movl sizeFinalResult, %eax
  movl %eax, lengthResult
  movl %eax, sizeCounter
  addl $3, sizeCounter
  xorl %eax, %eax

findInitialZerosResultBegin:
  movl $0, %edx
  decl sizeCounter
  movb finalResult(,%edx,1), %al
  incl %edx
  cmpl $0, lengthResult
  je findInitialZerosEndResult
  cmpl $'0', %eax
  je shorterLengthResult
  jmp findInitialZerosEndResult

shorterLengthResult:
  decl lengthResult

deleteInitialZerosResult:
  xorl %eax, %eax
  movb finalResult(,%edx,1), %al
  decl %edx
  movb %al, finalResult(,%edx,1)
  addl $2, %edx
  cmpl sizeCounter, %edx
  jle deleteInitialZerosResult

deleteRedundantResult:
  decl %edx
  movl $0, finalResult(,%edx,1)
  jmp findInitialZerosResultBegin

findInitialZerosEndResult:
	ret
