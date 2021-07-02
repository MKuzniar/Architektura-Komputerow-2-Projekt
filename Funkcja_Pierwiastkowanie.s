.equ LINUX_SYSCALL, 0x80
.equ STDIN, 0
.equ STDOUT, 1
.equ EXIT, 1
.equ WRITE, 4
.equ READ, 3

.section .bss

.equ ARGUMENTS, 8192
.lcomm argument1, ARGUMENTS
.lcomm argumentSize1, 4
.lcomm nextPair, ARGUMENTS

.lcomm index, 4

.equ RESULT, 16384
.lcomm finalResult, RESULT
.lcomm currentResult, RESULT

.lcomm carry, 1
.lcomm finalCarry, 1

.section .data
    base: .long 10
    size: .long 1024

    sizeCounter: .long 0
    sizeFinalResult: .long 0
    sizeCurrentResult: .long 0

    indexVar: .long 0
    partialResult: .long 0
    singleNumber: .long 0
    operationCounter: .long 4

    info:
      .ascii "Square root of decimal number \n-------------------------------\0"
    info_len = .-info

    first:
      .ascii "\nArgument: \0"
    first_len = .-first

    final:
      .ascii "\nFinal result: \0"
    final_len = .-final

  .section .text
  .globl rootFunction
  .type rootFunction, @function
    rootFunction:

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
    movl argumentSize1, %eax

alignArgument:
    incl %eax
    xorl %edx, %edx
    xorl %ecx, %ecx
    movl $2, %ecx
    idivl %ecx
    cmpl $0, %edx
    je fillWithZeros
    movl argumentSize1, %edi

alignArgumentPart1:
    movb argument1(,%edi,1), %bl
    incl %edi
    movb %bl, argument1(,%edi,1)
    subl $2, %edi
    cmpl $0, %edi
    jl alignArgumentPart2
    jmp alignArgumentPart1

alignArgumentPart2:
    incl %edi
    movb $'0', argument1(,%edi,1)
    incl argumentSize1
    xorl %eax, %eax

fillWithZeros:
    movl $0, %edi
    movl $'0', finalResult(,%edi,1)
    incl %edi
    movb $0xA, finalResult(,%edi,1)
    incl %edi
    movb $0xD, finalResult(,%edi,1)
    movl $0, index

getNextPair:
    xorl %eax, %eax
    movl argumentSize1, %eax
    cmpl %eax, indexVar
    jg showFinalResult

    xorl %edx, %edx
    xorl %edi, %edi
    movl indexVar, %edx
    movl index, %edi

    xorl %eax, %eax
    movb argument1(, %edx,1), %al
    xorl %ebx, %ebx
    movb nextPair(,%edi,1), %bl
    movl $0, nextPair(,%edi,1)
    movb %al, nextPair(,%edi,1)
    incl %edx
    incl %edi

    xorl %eax, %eax
    movb argument1(, %edx,1), %al
    movl $0, nextPair(,%edi,1)
    movb %al, nextPair(,%edi,1)

    incl %edi
    movb $0xA, nextPair(,%edi,1)
    incl %edi
    movb $0xD, nextPair(,%edi,1)

    addl $2, indexVar
    movl %edi, index
    subl $1, index

    xorl %eax, %eax
    movl base, %eax
    movl %eax, singleNumber

prepareCurrentResult:
    decl singleNumber
    xorl %eax, %eax
    xorl %ecx, %ecx
    xorl %ebx, %ebx
    xorl %edx, %edx
    movl sizeFinalResult, %ebx
    addl $2, %ebx

    xorl %edi, %edi
    xorl %edx, %edx
    movl operationCounter, %edx
    incl operationCounter
    movl $'0', currentResult(,%edi, 1)

fillWithZerosPart2:
    cmpl $0, %edx
    jl transferfinalResult

    incl %edi
    decl %edx
    movl $'0', currentResult(,%edi, 1)
    jmp fillWithZerosPart2

transferfinalResult:
    incl %edi
    movb finalResult(,%ecx,1), %al
    movb %al, currentResult(,%edi,1)
    incl %ecx
    cmpl %ecx, %ebx
    jge transferfinalResult

    movl %edi, sizeCurrentResult
    subl $2, sizeCurrentResult

    xorl %edi, %edi
    movl sizeCurrentResult, %edi

currentResultConvertion:
    movb currentResult(,%edi,1), %bl
    pushl $base
    pushl %ebx
    call charToInt
    addl $8, %esp

    imull $2, %eax
    addl carry, %eax
    movl $0, carry

    pushl %eax
    call intToChar
    addl $4, %esp
    movb %al, currentResult(,%edi,1)
    decl %edi

    cmpl $0, %edi
    jl currentResultConvertionPart1
    jmp currentResultConvertion

currentResultConvertionPart1:
    xorl %edi, %edi
    movl sizeCurrentResult, %edi
    addl $1, %edi
    incl sizeCurrentResult
    movl $'0', currentResult(,%edi,1)
    incl %edi
    movb $0xA, currentResult(,%edi,1)
    incl %edi
    movb $0xD, currentResult(,%edi,1)

    xorl %eax, %eax
    xorl %ecx, %ecx
    xorl %ebx, %ebx
    xorl %edx, %edx

currentResultModification:
    movl singleNumber, %ebx
    pushl %ebx
    call intToChar
    addl $4, %esp
    movl sizeCurrentResult, %edi
    movb %al, currentResult(,%edi,1)
    movl $0, carry
    xorl %edi, %edi
    movl sizeCurrentResult, %edi

currentResultModificationPart1:
    movb currentResult(,%edi,1), %bl
    pushl $base
    pushl %ebx
    call charToInt
    addl $8, %esp

    imull singleNumber, %eax
    addl carry, %eax
    movl $0, carry
    cmpl base, %eax
    jge currentResultModificationPart2

    pushl %eax
    call intToChar
    addl $4, %esp
    movb %al, currentResult(,%edi,1)
    decl %edi

    jmp currentResultFinish

currentResultModificationPart2:
    subl base, %eax
    incl carry
    cmpl base, %eax
    jge currentResultModificationPart2

    pushl %eax
    call intToChar
    addl $4, %esp

    movb %al, currentResult(,%edi,1)
    decl %edi

currentResultFinish:
    cmpl $0, %edi
    jl currentResultFinishPart1
    jmp currentResultModificationPart1

currentResultFinishPart1:
    call findInitialZeros
    xorl %eax, %eax
    xorl %ebx, %ebx
    xorl %ecx, %ecx
    movl $0, %edx
    movl index, %ecx

compareNextPair:
    cmpl %edx, %ecx
    jg compareNextPairPart1
    jmp beforeSubtraction

compareNextPairPart1:
    xorl %ebx, %ebx
    movb nextPair(,%edx,1), %bl
    pushl $base
    pushl %ebx
    call charToInt
    addl $8, %esp

    movb currentResult(,%edx,1), %bl
    pushl %eax
    pushl $base
    pushl %ebx
    call charToInt
    addl $8, %esp

    movl %eax, %ebx
    popl %eax
    incl %edx
    cmpl %eax, %ebx
    je compareNextPair
    cmpl %eax, %ebx
    jg prepareCurrentResult

beforeSubtraction:
    movl sizeCurrentResult, %edx

subtractionPart1:
    cmpl $0, %edx
    jl subtractionPart2
    movb nextPair(,%edx,1), %bl
    pushl $base
    pushl %ebx
    call charToInt
    addl $8, %esp

    movb currentResult(,%edx,1), %bl
    pushl %eax
    pushl $base
    pushl %ebx
    call charToInt
    addl $8, %esp

    movl %eax, %ebx
    popl %eax

    subl %ebx, %eax
    subl carry, %eax
    movl $0, carry
    cmpl $0, %eax

    pushl %eax
    call intToChar
    addl $4, %esp
    movb %al, nextPair(,%edx,1)
    decl %edx
    jmp subtractionPart1

subtractionPart2:
    xorl %eax, %eax
    movl singleNumber, %eax
    pushl %eax
    call intToChar
    addl $4, %esp

    xorl %edi, %edi
    xorl %ebx, %ebx
    movl partialResult, %edi
    incl partialResult
    movb finalResult(,%edi,1), %bl
    cmpl $48, %ebx
    jne addToFinalResult

    movb %al, finalResult(,%edi,1)
    jmp getNextPair

addToFinalResult:
    incl sizeFinalResult
    movb %al, finalResult(,%edi,1)
    incl %edi
    movb $0xA, finalResult(,%edi,1)
    incl %edi
    movb $0xD, finalResult(,%edi,1)

    jmp getNextPair

showFinalResult:
    xorl %edi, %edi
    xorl %edx, %edx
    xorl %ecx, %ecx
    movl sizeFinalResult, %edi
    movl %edi, %ecx

    subl $0, %ecx
    addl $2, %edi
    movl %edi, %edx
    incl %edx

    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $final, %ecx
    movl $final_len, %edx
    int $LINUX_SYSCALL

    movl $WRITE, %eax
    movl $STDOUT, %ebx
    movl $finalResult, %ecx
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
    jbe intToCharEnd

intToCharEnd:
    movl %ebp, %esp
    popl %ebp
    ret


.type findInitialZeros,@function
findInitialZeros:
    xorl %edx, %edx
    xorl %eax, %eax
    xorl %ecx, %ecx
    movl sizeCurrentResult, %eax
    movl %eax, sizeCounter
    addl $3, sizeCounter
    xorl %eax, %eax

findInitialZerosBegin:
    movl $0, %edx
    movb currentResult(,%edx,1), %al
    incl %edx
    xorl %ebx, %ebx
    movl index, %ebx
    decl %ebx
    cmpl %ebx, sizeCurrentResult
    je findInitialZerosEnd
    cmpl $'0', %eax
    je deleteInitialZerosBegin
    jmp findInitialZerosEnd

deleteInitialZerosBegin:
    decl sizeCounter
    decl sizeCurrentResult

deleteInitialZeros:
    xorl %eax, %eax
    movb currentResult(,%edx,1), %al
    decl %edx
    movb %al, currentResult(,%edx,1)
    addl $2, %edx
    cmpl sizeCounter, %edx
    jle deleteInitialZeros

deleteRedundand:
    decl %edx
    movl $0, currentResult(,%edx,1)
    jmp findInitialZerosBegin

findInitialZerosEnd:
    ret
