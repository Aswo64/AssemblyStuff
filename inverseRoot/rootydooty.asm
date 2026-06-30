bits 64
default rel

section .data
    fmt             db      "%f", 10, 0
    hexaPre         db      "0x", 0
    input_size      equ     100



section .bss
; could use the heap to do this instead, using windows API, but this works, using windows API works well with memory as using syscalls for every allocation is very slow as
; the OS gives memory in "pages", so if you want to allocate 10 bytes only, you can't, you must take 4096 bytes at a time, this can lead to wasted byte, however 
; what the malloc windows API does is it keeps track of the memory it already has from syscalls and splits the page into smaller chunks, allowing u to fit 10 bytes in there 
    hexStr         resb    10
    alignb 8
    bytesWritten   resq    1
    inputBuffer    resb    input_size
    bytesRead      resq    1

section .text
    global main
    global toBuoyancy
    global binaryToHexa
    global leInput
    global invSquare
    extern GetStdHandle
    extern WriteConsoleA
    extern ReadConsoleA
    extern ExitProcess
    extern printf


main:
    sub rsp, 40

    call leInput

    mov r9, inputBuffer
    call toBuoyancy
    rsqrtss xmm6, xmm0

    call invSquare

    cvtss2sd xmm0, xmm0
    movq rdx, xmm0
    lea rcx, [fmt]
    call printf

    
    cvtss2sd xmm6, xmm6
    movq rdx, xmm6
    lea rcx, [fmt]
    call printf

    xor rcx, rcx
    call ExitProcess


invSquare:
    ; Hexa representation of 0.5 using IEE 754 standard
    mov r8d, 0x3F000000
    movd xmm4, r8d

    ; same for 1.5
    mov r9d, 0x3FC00000
    movd xmm5, r9d

    movss xmm1, xmm0
    movss xmm2, xmm4
    mulss xmm1, xmm2

    movd eax, xmm0
    shr eax, 1
    mov ecx, 0x5F3759DF
    sub ecx, eax
    movd xmm0, ecx

    ; Doing only one Newton iteration causes for an error of 0.175%
    movss xmm3, xmm0
    mulss xmm3, xmm3
    mulss xmm3, xmm1
    movss xmm2, xmm5
    subss xmm2, xmm3
    mulss xmm0, xmm2 

    movss xmm3, xmm0
    mulss xmm3, xmm3
    mulss xmm3, xmm1
    movss xmm2, xmm5
    subss xmm2, xmm3
    mulss xmm0, xmm2 
    ret

leInput:
    sub rsp, 40

    mov rcx, -10
    call GetStdHandle
    mov rcx, rax
    lea rdx, [inputBuffer]
    mov r8d, input_size
    lea r9, [bytesRead]
    mov qword [rsp + 32], 0
    call ReadConsoleA

    add rsp, 40
    ret


binaryToHexa:
.loop:
    mov edx, eax
    and edx, 0x0F
    cmp dl, 9
    jbe .isNum
    add dl, 7
.isNum:
    add dl, '0'
    mov [r8], dl
    dec r8
    shr eax, 4
    dec ecx
    jnz .loop

    add r8, 9
    mov [r8], 0x0A
    ret



toBuoyancy:
    xorps xmm0, xmm0
    xorps xmm1, xmm1
    mov eax, 10
    cvtsi2ss xmm2, eax
    ; I used eax here, using so zeros out the upper 32 bits of rax, js saying
    ; It is recommended normally to not use bigger registers than you need as the instruction is longer, and thus slower
    mov eax, 0x3DCCCCCC
    movd xmm3, eax
    movd xmm4, eax
.inFront:
    movzx rax, byte [r9]
    inc r9
    cmp al, 0
    je .fini
    cmp al, 13
    je .fini
    cmp al, 10
    je .fini
    cmp al, '.'
    je .leBack
    sub al, '0'
    mulss xmm0, xmm2
    cvtsi2ss xmm1, rax
    addss xmm0, xmm1
    jmp .inFront
.leBack:
    movzx rax, byte [r9]
    inc r9
    cmp al, '.'
    je .leBack
    cmp al, 13
    je .fini
    cmp al, 10
    je .fini
    cmp al, 0
    je .fini
    sub al, '0'
    cvtsi2ss xmm1, rax
    mulss xmm1, xmm3
    addss xmm0, xmm1
    mulss xmm3, xmm4
    jmp .leBack
.fini:
    ret


printShi:
    sub rsp, 40

    mov rcx, -11
    call GetStdHandle
    mov rcx, rax
    mov rdx, r9
    lea r9, [bytesWritten]
    mov qword [rsp + 32], 0
    call WriteConsoleA

    add rsp, 40
    ret
