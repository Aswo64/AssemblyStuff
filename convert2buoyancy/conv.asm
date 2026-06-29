bits 64
default rel

section .data
    fmt             db      "%f", 10, 0
    hexaPre         db      "0x", 0
    input_size      equ     100
    floatDecimal    dd      0.1


section .bss
    ; While floats only require 4 bytes, we must use 8 bytes as each number requires 2 hex characters to represent them in ASCII
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
    extern GetStdHandle
    extern WriteConsoleA
    extern ReadConsoleA
    extern ExitProcess
    extern printf


main:
    sub rsp, 40

    call leInput

    ; When doing assembly in Windows, Microslop has a strict set of rules for specific registers and splits them in two, volative and non-volative registers
    ; Volative registers are as the name suggest, volative meaning the value inside the register can change anytime and does not matter to the previous function
    ; Non-volative registers are the opposite, the previous function can rely on the value and should not be overwritten, so u can still use the register
    ; but js remember to save the value and restore it after the function call, or just use a different register
    ; So here I initially used RDI, but that is a non-volative register, so I changed it to r9, its js good practise  
    mov r9, inputBuffer
    call toBuoyancy
    movd eax, xmm0
    mov ecx, 8
    lea r8, [hexStr + 7]
    call binaryToHexa

    mov r9, hexaPre
    mov r8, 2
    call printShi

    mov r9, hexStr
    mov r8, 9
    ; Important thing, I tried calling this function twice, but it only printed once, I later found out it was because r9 is a volative register, meaning when the function WriteConsoleA
    ; is called, it overwrites the value of r9 and nothing left is there 
    call printShi

    ; cvtss2sd xmm0, xmm0
    ; movq rdx, xmm0
    ; lea rcx, [fmt]
    ; call printf
    

    xor rcx, rcx
    call ExitProcess



; You will see in these functions that there are some where I subtract 40 from rsp, this is because some of these functions 
; will call other functions, and those functions will use the stack, specifically the 32 bytes that are not the return address that is pushed
; it is windows protocol to use 4 registers as inputs, and to accomodate those 4 registers there are those 32 bytes as a notepad in the stack.
; Therefore to stop a return address from changing to sum bs and the rip jumping to sumwhere random, we have to sub rsp 
; Most CPU's take in 64 byte cache lines to quickly run and access memory, so they made 16 bytes the sweet spot
leInput:
    sub rsp, 40

    mov rcx, -10
    call GetStdHandle
    ; When involving tranferring data using memory dereferencing, you MUST specify how many bytes to transfer
    ; For registers u dont have to doe
    mov rcx, rax
    lea rdx, [inputBuffer]
    mov r8d, input_size
    lea r9, [bytesRead]
    mov qword [rsp + 32], 0
    call ReadConsoleA

    add rsp, 40
    ret


binaryToHexa:
; A binary to hexa conversion using ASCII
.loop:
    ; 0x0F is 0000 1111 so it acts as a mask for the lowest 4 bits
    ; You need an extra register bcs you must mask it everytime and shift the eax register to get the next 4
    mov edx, eax
    and edx, 0x0F
    ; If the value is more than 9, it becomes letters, and letters are 7 more than numbers in ASCII
    cmp dl, 9
    jbe .isNum
    add dl, 7
.isNum:
    add dl, '0'
    mov [r8], dl
    dec r8
    shr eax, 4
    ; the CPU's internal zero flag updates whenever there is a dec instruction, and will turn to 1 if that register is 0, so we can use jnz (jump if not zero) to loop easily
    dec ecx
    jnz .loop

    add r8, 9
    mov [r8], 0x0A
    ret



toBuoyancy:
    xorps xmm0, xmm0
    xorps xmm1, xmm1

    mov rax, 10
    cvtsi2ss xmm2, rax
    movss xmm3, [floatDecimal]
    movss xmm4, [floatDecimal]
.inFront:
    ; At first I thought it might be alr to js use the inputBuffer as the input and increment using the memory
    ; But i found out that using a register to incrememnt is faster than fetching the memory and incrementing it 
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


; Extra info:
; When you push, it will automatically increment the rsp by 8 bytes downwards, but also when you pop, 
; it will look at the current place of rsp, and copy whatever is inside that emmory address + the 7 bytes above and then move rsp up by 7
; pushing/popping can only be done with registers (rax), but not on eax and stuff, ts is because of aligning, you must change 8 bytes
; there is the exception of 2 bytes, so you can use ax, but this was only for backwards compatiblity