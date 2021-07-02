.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3

.section .bss

.equ ARGUMENTS, 8192
.equ RESULT, 16384
.equ SIZE, 8196
.lcomm argument1, ARGUMENTS
.lcomm argument2, ARGUMENTS
.lcomm firstArgumentValue, 4

.lcomm argumentSize1, 4
.lcomm argumentSize2, 4
.lcomm argumentSize3, 4
.lcomm partialProduct, RESULT
.lcomm finalResult, RESULT
.lcomm carry, 1
.lcomm finalCarry, 1

.section .data
    base: .long 10
    currentSize: .long 8196
    sizeCounter: .long 0

    info:
    .ascii "Multiplication of two decimal numbers\n-------------------------------\0"
    info_len = .-info

    first:
    .ascii "\nFirst argument: \0"
    first_len = .-first

    second:
    .ascii "Second argument: \0"
    second_len = .-second

    final:
    .ascii "\nFinal result: \0"
    final_len = .-final

    newLine:
    .ascii " \n\0"
    new_len = .-newLine

.section .text
.globl multiFunction
.type multiFunction, @function
  multiFunction:


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
    movl %eax, argumentSize1

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
    movl %eax, argumentSize2
    xorl %edx, %edx
    movl argumentSize2, %edx
    movl %edx, argumentSize3
    xorl %edx, %edx


checkCondition:
    cmpl $0, argumentSize1
    jl showFinalResult
    xorl %edi, %edi
    movl $SIZE, %edi
    decl %edi
    xorl %ecx, %ecx
    movl $SIZE, %ecx
    subl currentSize, %ecx
    decl currentSize

main:
    cmpl $0, %ecx
    je firstToInt
    movb $0, partialProduct(,%edi,1)
    decl %edi
    decl %ecx
    jmp main

firstToInt:
    xorl %ecx, %ecx
    xorl %edx, %edx

    movl $0, firstArgumentValue
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
    movl %eax, firstArgumentValue
    movl argumentSize3, %edx
    movl %edx, argumentSize2
    jmp secondToInt

firstToIntEnd:
    xorl %eax, %eax
    movl %eax, firstArgumentValue

secondToInt:
    xorl %eax, %eax
    movl argumentSize2, %edx
    cmpl $0, %edx
    jl secondToIntEnd
    decl argumentSize2
    movb argument2(,%edx,1), %bl

    pushl $base
    pushl %ebx
    call charToInt
    addl $8, %esp
    jmp multiplication

secondToIntEnd:
    cmpl $0, argumentSize1
    jge multiplication
    cmpl $0, argumentSize2
    jge multiplication
    cmpl $0, carry
    jg multiplication
    jmp completePartialProduct

multiplication:
    xorl %ecx, %ecx
    imull firstArgumentValue, %eax
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
    movb %al, partialProduct(,%edi,1)
    decl %edi
    xorl %ecx, %ecx
    movl argumentSize2, %ecx
    addl $1, %ecx
    cmpl $0, %ecx
    jg secondToInt
    xorl %ecx, %ecx
    movl carry, %ecx
    cmpl $0, %ecx
    jne secondToInt

completePartialProduct:
    decl %edi
    cmpl $0, %edi
    jl createFinalResult
    movb $0, partialProduct(,%edi,1)
    jmp completePartialProduct

createFinalResult:
    call addPartialProducts
    jmp checkCondition

showFinalResult:
    call findInitialZeros
    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $final, %ecx
    movl $final_len, %edx
    int $LINUX_SYSCALL

    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $finalResult, %ecx
    movl $ARGUMENTS, %edx
    int $LINUX_SYSCALL

    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $newLine, %ecx
    movl $new_len, %edx
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

.type addPartialProducts,@function
addPartialProducts:
    pushl %ebp
    movl %esp, %ebp
    xorl %edx, %edx
    movl $SIZE, %edx
    decl %edx

step1:
    xorl %ebx, %ebx
    movb partialProduct(,%edx,1), %bl
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
    xorl %eax, %eax
    xorl %ecx, %ecx
    movl $SIZE, %eax
    movl %eax, sizeCounter
    addl $2, sizeCounter
    xorl %eax, %eax

findInitialZerosBegin:
    xorl %edx, %edx
    decl sizeCounter
    movb finalResult(,%edx,1), %al
    incl %edx
    cmpl $'0', %eax
    je deleteInitialZeros
    ret

deleteInitialZeros:
    xorl %eax, %eax
    movb finalResult(,%edx,1), %al
    decl %edx
    movb %al, finalResult(,%edx,1)
    addl $2, %edx
    cmpl sizeCounter, %edx
    jle deleteInitialZeros
    decl %edx
    movl $0, finalResult(,%edx,1)
    jmp findInitialZerosBegin
