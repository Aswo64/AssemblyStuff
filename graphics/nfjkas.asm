default rel
bits 64

extern ExitProcess
extern GetModuleHandleA
extern CreateWindowExA
extern RegisterClassExA
extern DefWindowProcA
extern GetMessageA
extern PeekMessageA
extern DispatchMessageA
extern GetDC
extern SetPixel
extern ReleaseDC
extern ShowWindow
extern SetTimer

section .data
    window_class_name db "MyWin64Class", 0
    window_title      db "za windows", 0

    pixel_x dq 20
    pixel_y dq 20

section .bss
    hwnd        resq 1
    wnd_class   resb 80
    msg         resb 48

section .text
global main

main:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    xor rcx, rcx
    call GetModuleHandleA

    mov r12, rax
    lea rdi, [wnd_class]
    xor eax, eax
    mov ecx, 10
    rep stosq

    ; -----------------------------------------
    ; WNDCLASSEXA
    ;
    ; +0  cbSize
    ; +4  style
    ; +8  lpfnWndProc
    ; +16 cbClsExtra
    ; +20 cbWndExtra
    ; +24 hInstance
    ; +32 hIcon
    ; +40 hCursor
    ; +48 hbrBackground
    ; +56 lpszMenuName
    ; +64 lpszClassName
    ; +72 hIconSm
    ; -----------------------------------------

    mov dword [wnd_class + 0], 80
    mov dword [wnd_class + 4], 3
    lea rax, [window_procedure]
    mov qword [wnd_class + 8], rax
    mov qword [wnd_class + 24], r12
    lea rax, [window_class_name]
    mov qword [wnd_class + 64], rax

    lea rcx, [wnd_class]
    call RegisterClassExA

    test rax, rax
    jz registration_failed
    xor rcx, rcx

    lea rdx, [window_class_name]
    lea r8, [window_title]

    mov r9d, 0x00CF0000


    mov dword [rsp + 32], 600
    mov dword [rsp + 40], 350
    mov dword [rsp + 48], 640
    mov dword [rsp + 56], 480
    mov qword [rsp + 64], 0
    mov qword [rsp + 72], 0
    mov qword [rsp + 80], r12
    mov qword [rsp + 88], 0

    call CreateWindowExA

    test rax, rax
    jz create_window_failed

    mov [hwnd], rax

    mov rcx, rax
    mov edx, 5
    call ShowWindow


    mov rcx, [hwnd]
    mov edx, 1
    mov r8d, 1
    xor r9d, r9d
    call SetTimer


message_loop:
    lea rcx, [msg]

    lea rcx, [msg]
    xor rdx, rdx
    xor r8, r8
    xor r9, r9
    ; mov dword [rsp + 32], 1
    call GetMessageA
    cmp rax, -1
    jle exit_program

    test rax, rax
    jz .go_again

    lea rcx, [msg]
    call DispatchMessageA
    jmp message_loop

.go_again:
    jmp message_loop


registration_failed:
    mov ecx, 1
    call ExitProcess


create_window_failed:
    mov ecx, 2
    call ExitProcess


exit_program:
    xor ecx, ecx
    call ExitProcess

window_procedure:

    push rbp
    mov rbp, rsp
    sub rsp, 64

    cmp edx, 2
    je handle_destroy

    cmp edx, 0x0113
    je handle_timer

    call DefWindowProcA

    leave
    ret


handle_timer:

    inc qword [pixel_x]

    mov rcx, [hwnd]
    call GetDC

    test rax, rax
    jz timer_done

    mov [rsp + 32], rax
    mov rcx, rax
    mov rdx, [pixel_x]
    mov r8, [pixel_y]
    mov r9d, 0x000000FF
    call SetPixel


    mov rcx, [hwnd]
    mov rdx, [rsp + 32]

    call ReleaseDC

timer_done:
    xor eax, eax
    leave
    ret



handle_destroy:

    xor ecx, ecx
    call ExitProcess

    xor eax, eax
    leave
    ret