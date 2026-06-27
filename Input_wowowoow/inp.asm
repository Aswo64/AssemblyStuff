bits 64
default rel

section .data
    message         db      "Hello World!", 0x0A, 0
    message_len     equ     $ - message
    input_size      equ     100


section .bss
    bytes_written   resq    1
    input_buffer    resb    input_size
    bytes_read      resq    1

section .text
    global main
    extern GetStdHandle
    extern WriteConsoleA
    extern ReadConsoleA
    extern ExitProcess


main:
    sub rsp, 40

    ; Windows will automatically insert a \r\n at the end of the input buffer, \n being 0x0A and \r being 0x0D, to get rid of this, we can just subtract 2 from the bytes_read arg
    mov rcx, -10
    call GetStdHandle
    mov qword [rsp + 32], 0
    mov rcx, rax
    lea rdx, [input_buffer]
    mov r8d, input_size
    lea r9, [bytes_read]
    call ReadConsoleA


    mov rdx, rax
    call printShi

    xor rcx, rcx
    call ExitProcess


printShi:
    mov rcx, -11
    call GetStdHandle
    mov rcx, rax
    mov r8d, [bytes_read]
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call WriteConsoleA
    ret