default rel
bits 64

extern ExitProcess
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
extern Sleep
extern SetTimer
extern InvalidateRect
extern BeginPaint
extern EndPaint
extern CreateThread
extern ExitThread
extern UpdateWindow

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

    xor ecx, ecx
    xor edx, edx
    lea r8, [new_thread]
    xor r9d, r9d

    mov qword [rsp+32], 0 
    mov qword [rsp+40], 0

    call CreateThread

    ; mov rcx, [hwnd]
    ; mov rdx, 1
    ; mov r8, 10
    ; xor r9, r9
    ; call SetTimer

message_loop:
    ; lea rcx, [msg]
    ; xor rdx, rdx
    ; xor r8, r8
    ; xor r9, r9
    ; call GetMessageA
    ; cmp rax, 0
    ; jle exit_program

    ; lea rcx, [msg]
    ; call DispatchMessageA
    ; jmp message_loop

    lea rcx, [msg]
    xor rdx, rdx
    xor r8, r8
    xor r9, r9
    mov dword [rsp + 32], 1
    call PeekMessageA
    cmp rax, -1
    jle exit_program

    test rax, rax
    jz .go_again

    lea rcx, [msg]
    call DispatchMessageA
    jmp message_loop

.go_again:
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
    inc qword [pixel_y]

    mov rcx, [hwnd]
    xor rdx, rdx
    mov r8, 0
    call InvalidateRect

    xor rax, rax
    leave
    ret

handle_paint:
    sub rsp, 112

    mov [rsp + 32], rcx
    lea rdx, [rsp + 40]
    call BeginPaint

    mov rcx, 200
    mov rdx, 200
    mov r8, 400
    mov r9, 800
    call draw_line

    ; mov rcx, rax
    ; mov rdx, [pixel_x]
    ; mov r8, [pixel_y]
    ; mov r9d, 0x000000FF
    ; call SetPixel

    mov rcx, [rsp + 32]
    lea rdx, [rsp + 40]
    call EndPaint

    add rsp, 112
    xor eax, eax
    leave
    ret


handle_destroy:
    xor rcx, rcx
    call ExitProcess
    xor rax, rax
    leave
    ret

new_thread:
    sub rsp, 40
    inc qword [pixel_x]
    inc qword [pixel_y]

    mov rcx, [hwnd]
    xor rdx, rdx
    mov r8, 0
    call InvalidateRect
    mov rcx, [hwnd]
    call UpdateWindow

    mov ecx, 10
    call Sleep

    xor rax, rax
    jmp new_thread

; rax = HDC
; rcx = x0
; rdx = y0
; r8 = x1
; r9 = y1
draw_line:
; this function is indirectly being called by windows, therefore if we use non-volatile registers, we must return them back when done, a.k.a popping these back when done
; also pushing two is best as each register has 8 bytes, and we need the 16 byte alignment, so pushing two aligns it properly for setPixel function to work
    push rbx
    push rdi
    push rsi 
    push r12
    push r13
    push r14
    push r15

; Instead of 32, had to do 40 since using r15 madeit not 16-byte aligned, so i added 8 bytes on top of 32 to get 40
    sub rsp, 40

; rbx = x0
    mov rbx, rcx
; rdi = y0
    mov rdi, rdx
; rsi = x1
    mov rsi, r8
; r13 = HDC
    mov r13, rax

    sub r9, rdx
    sub r8, rcx
    cvtsi2ss xmm0, r9
    cvtsi2ss xmm1, r8
    divss xmm0, xmm1
    mov eax, 1
    shl eax, 15
    cvtsi2ss xmm1, eax
    mulss xmm0, xmm1
; we put the integer representation of the fraction in r12
    cvtss2si r12, xmm0

; r14 is the accumulator, do NOT touch it
    xor r14, r14

.again:
    inc rbx

    cmp rbx, rsi
    je .done

    add r14, r12

    cmp r14, 32768
    jb .calculate 
    sub r14, 32768
    inc rdi

.calculate:
; calculating brightness using rdx, try not to touch it
    mov r15, r14
    shr r15, 7

    mov rcx, r13
    mov rdx, rbx
    mov r8, rdi
    mov r9d, r15d
    call SetPixel

    mov rcx, r13
    mov rdx, rbx
    mov r8, rdi
    inc r8
    neg r15
    add r15, 255
    mov r9d, r15d
    call SetPixel

    jmp .again
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi 
    pop rdi
    pop rbx
    leave 
    ret





    



    






