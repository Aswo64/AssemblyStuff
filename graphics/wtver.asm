default rel
bits 64

extern ExitProcess
extern CreateWindowExA
extern RegisterClassExA
extern DefWindowProcA
extern GetMessageA
extern DispatchMessageA
extern GetDC
extern SetPixel
extern ReleaseDC
extern ShowWindow
extern Sleep
extern SetTimer
extern InvalidateRect

section .data
    window_class_name db "MyWin64Class", 0
    window_title      db "za windows", 0
    pixel_x         dq 20
    pixel_y         dq 20

section .bss
    hwnd        resq    1
    wnd_class   resb    80
    msg         resb    48

section .text
global main
main:
    push rbp
    mov rbp, rsp
    sub rsp, 96

    mov rdi, wnd_class
    xor rax, rax
    mov rcx, 10
    rep stosq

    mov dword [wnd_class], 80
    mov dword [wnd_class + 4], 3
    
    lea rax, [window_procedure]
    mov qword [wnd_class + 8], rax

    lea rax, [window_class_name]
    mov qword [wnd_class + 64], rax

    lea rcx, [wnd_class]
    call RegisterClassExA

    xor rcx, rcx
    lea rdx, [window_class_name]
    lea r8, [window_title]
    mov r9d, 0x10CF0000

    mov dword [rsp + 32], 600
    mov dword [rsp + 40], 350
    mov dword [rsp + 48], 640
    mov dword [rsp + 56], 480
    mov qword [rsp + 64], 0
    mov qword [rsp + 72], 0
    mov qword [rsp + 80], 0
    mov qword [rsp + 88], 0
    call CreateWindowExA

    mov [hwnd], rax
    mov rcx, rax
    mov rdx, 5
    call ShowWindow

    mov rcx, [hwnd]
    mov rdx, 1
    mov r8, 10
    xor r9, r9
    call SetTimer

message_loop:
    lea rcx, [msg]
    xor rdx, rdx
    xor r8, r8
    xor r9, r9
    call GetMessageA
    cmp rax, 0
    jle exit_program

    lea rcx, [msg]
    call DispatchMessageA
    jmp message_loop

exit_program:
    xor rcx, rcx
    call ExitProcess


window_procedure:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    cmp rdx, 2
    je handle_destroy
    cmp rdx, 15
    je handle_paint
    cmp rdx, 0x0113
    je handle_timer

default_processing:
    call DefWindowProcA
    leave
    ret

handle_timer:
    inc qword [pixel_x]

    mov rcx, [hwnd]
    xor rdx, rdx
    mov r8, 0
    call InvalidateRect

    xor rax, rax
    leave
    ret

handle_paint:
    mov rcx, [hwnd]
    call GetDC


    push rax
    mov rcx, rax
    mov rdx, [pixel_x]
    mov r8, [pixel_y]
    mov r9d, 0x000000FF
    call SetPixel


    mov rcx, [hwnd]
    pop rax
    mov rdx, rax

    call ReleaseDC

    xor rax, rax
    leave
    ret


handle_destroy:
    xor rcx, rcx
    call ExitProcess
    xor rax, rax
    leave
    ret