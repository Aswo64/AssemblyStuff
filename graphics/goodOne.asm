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
extern GetClientRect
extern GetStockObject
extern FillRect
extern GetRawInputData
extern RegisterRawInputDevices

section .data
    window_class_name db "MyWin64Class", 0
    window_title      db "za windows", 0
    mouse_raw_input_device:
        dw 1
        dw 2
        dd 256
        dq 0
    pixel_x         dq 20
    pixel_y         dq 20
    v_coords:
        dd 0.25, 0.25, -0.25
        dd -0.25, 0.25, -0.25
        dd -0.25, -0.25, -0.25
        dd 0.25, -0.25, -0.25
        dd 0.25, 0.25, 0.25
        dd -0.25, 0.25, 0.25
        dd -0.25, -0.25, 0.25
        dd 0.25, -0.25, 0.25
    
    f_coords:
        dd  1, 2, 3
        dd  1, 3, 4
        dd  5, 7, 6
        dd  5, 8, 7
        dd  4, 8, 5
        dd  4, 5, 1
        dd  1, 5, 6
        dd  1, 6, 2
        dd  2, 6, 7
        dd  2, 7, 3
        dd  4, 3, 7
        dd  4, 7, 8


section .bss
    hwnd        resq    1
    wnd_class   resb    80
    msg         resb    48
    input_buffer resb 64
    input_buffer_size resd 64

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

    mov ecx, 4
    call GetStockObject
    mov [wnd_class+48], rax

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

    mov rax, [hwnd]
    mov [mouse_raw_input_device + 8], rax

    lea rcx, [mouse_raw_input_device]
    mov edx, 1
    mov r8d, 16
    call RegisterRawInputDevices



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

exit_program:
    xor rcx, rcx
    call ExitProcess


window_procedure:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    cmp rdx, 2
    je handle_destroy
    cmp rdx, 15
    je handle_paint
    cmp rdx, 0x0113
    je handle_timer
    cmp rdx, 0x00FF
    je handle_mouse

default_processing:
    call DefWindowProcA
    leave
    ret

handle_mouse:
    mov rcx, r9
    mov edx, 0x10000003
    lea r8, [input_buffer]
    lea r9, [input_buffer_size]
    mov dword [rsp+32], 24
    call GetRawInputData

    movsxd rax, dword [input_buffer + 36]
    add [pixel_x], rax
    movsxd rax, dword [input_buffer + 40]
    add [pixel_y], rax

    xor rax, rax
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

    mov rcx, 100
    mov rdx, 100
    mov r8, [pixel_x]
    mov r9, [pixel_y]
    call draw_line

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
.loop:
    ; inc qword [pixel_x]
    ; inc qword [pixel_y]

    mov rcx, [hwnd]
    xor rdx, rdx
    mov r8, 1
    call InvalidateRect
    mov rcx, [hwnd]
    call UpdateWindow

    mov ecx, 10
    call Sleep

    xor rax, rax
    jmp .loop




; rax = HDC
; rcx = x0
; rdx = y0
; r8 = x1
; r9 = y1
; Draws line wow 
draw_line:
    ; aligning to 16 bytes
        sub rsp, 48
    ; this function is indirectly being called by windows, therefore if we use non-volatile registers, we must return them back when done, a.k.a popping these back when done
    ; also pushing two is best as each register has 8 bytes, and we need the 16 byte alignment, so pushing two aligns it properly for setPixel function to work
        push rbx
        push rdi
        push rsi
        push r12
        push r13
        push r14
        push r15

        
    ; rbx = x0
        mov rbx, rcx
    ; rdi = y0
        mov rdi, rdx
    ; rsi = x1
        mov rsi, r8
    ; r15 = y1
        mov r15, r9
    ; r13 = HDC
        mov r13, rax

        cmp rbx, rsi
        je .vert_line

        mov r12, rbx
        mov r14, r8

        sub r12, r14
        js .continue

        xchg rbx, rsi
        xchg rcx, r8
        xchg rdi, r15
        xchg r9, rdx
        

        

    .continue:
        sub r9, rdx
        sub r8, rcx
        
        mov rdx, r9
        neg r9
        cmovs r9, rdx

        mov rcx, r8
        neg r8
        cmovs r8, rcx
        
        cmp r9, r8
        ja .reciprocal
        cvtsi2ss xmm0, rdx
        cvtsi2ss xmm1, rcx
        divss xmm0, xmm1
        mov eax, 1
        shl eax, 15
        cvtsi2ss xmm1, eax
        mulss xmm0, xmm1
    ; we put the integer representation of the fraction in r12
        cvtss2si r12, xmm0
    ; r14 is the accumulator, do NOT touch it
        xor r14, r14

    ; These two pixel drawings are for endpoints
        mov rcx, r13
        mov rdx, rbx
        mov r8, rdi
        mov r9d, 0xFF
        call SetPixel

        mov rcx, r13
        mov rdx, rsi
        mov r8, r15
        mov r9d, 0xFF
        call SetPixel

        test r12, r12
        js .negative_x

        jmp .again_x

    .negative_x:
        neg r12
        jmp .again_x_down

    .reciprocal:
        cvtsi2ss xmm0, rcx
        cvtsi2ss xmm1, rdx
        divss xmm0, xmm1
        mov eax, 1
        shl eax, 15
        cvtsi2ss xmm1, eax
        mulss xmm0, xmm1
        cvtss2si r12, xmm0

    ; These two pixel drawings are for endpoints, but before we exchange the major axis and change the break case to make it w.r.t y 
        mov rcx, r13
        mov rdx, rbx
        mov r8, rdi
        mov r9d, 0xFF
        call SetPixel

        mov rcx, r13
        mov rdx, rsi
        mov r8, r15
        mov r9d, 0xFF
        call SetPixel

        xchg rbx, rdi
    ; Instead of seeing x0 = x1, we now see if y0 = y1
        mov rsi, r15
    ; r14 is the accumulator, do NOT touch it
        xor r14, r14

        test r12, r12
        js .negative_y

        jmp .again_y

    .negative_y:
        neg r12,
        jmp .again_y_down


    .again_x:

        inc rbx
        cmp rbx, rsi
        je .done

        add r14, r12

        cmp r14, 32768
        jb .calculatex
        sub r14, 32768
        inc rdi

    .calculatex:
    ; calculating brightness using rdx, try not to touch it
        mov r15, r14
        shr r15, 7

        mov rcx, r13
        mov rdx, rbx
        mov r8, rdi
        inc r8
        mov r9d, r15d
        call SetPixel

        mov rcx, r13
        mov rdx, rbx
        mov r8, rdi
        neg r15
        add r15, 255
        mov r9d, r15d
        call SetPixel

        jmp .again_x


    .again_x_down:
        inc rbx

        cmp rbx, rsi
        je .done

        add r14, r12

        cmp r14, 32768
        jb .calculatex_down
        sub r14, 32768
        dec rdi

    .calculatex_down:
    ; calculating brightness using rdx, try not to touch it
        mov r15, r14
        shr r15, 7

        mov rcx, r13
        mov rdx, rbx
        mov r8, rdi
        dec r8
        mov r9d, r15d
        call SetPixel

        mov rcx, r13
        mov rdx, rbx
        mov r8, rdi
        neg r15
        add r15, 255
        mov r9d, r15d
        call SetPixel

        jmp .again_x_down


    .again_y:
        inc rbx

        cmp rbx, rsi
        je .done

        add r14, r12

        cmp r14, 32768
        jb .calculatey
        sub r14, 32768
        inc rdi

    .calculatey:
    ; calculating brightness using rdx, try not to touch it
        mov r15, r14
        shr r15, 7

        mov rcx, r13
        mov rdx, rdi
        inc rdx
        mov r8, rbx
        mov r9d, r15d
        call SetPixel

        mov rcx, r13
        mov rdx, rdi
        mov r8, rbx
        neg r15
        add r15, 255
        mov r9d, r15d
        call SetPixel

        jmp .again_y

    .again_y_down:
        dec rbx

        cmp rbx, rsi
        je .done

        add r14, r12

        cmp r14, 32768
        jb .calculatey_down
        sub r14, 32768
        inc rdi

    .calculatey_down:
    ; calculating brightness using rdx, try not to touch it
        mov r15, r14
        shr r15, 7

        mov rcx, r13
        mov rdx, rdi
        inc rdx
        mov r8, rbx
        mov r9d, r15d
        call SetPixel

        mov rcx, r13
        mov rdx, rdi
        mov r8, rbx
        neg r15
        add r15, 255
        mov r9d, r15d
        call SetPixel

        jmp .again_y_down

    ; rdi = y0
    ; r15 = y1
    .vert_line:
    ;     cmp r15, rbx
    ;     je .point_perchance 
    ; .nvm_frown:
        cmp rdi, r15
        ; Previously used jb instead of jl, but jb only works with unsigned integers (only positive numbers), 
        ; so here, theres no harm to use jl, as if x is negative, it will cause for an infinite loop
        jl .vert_line_up
        jmp .vert_line_down
        

    .vert_line_up:
        cmp rdi, r15
        je .done
        inc rdi
        mov rcx, r13
        mov rdx, rbx
        mov r8, rdi
        mov r9d, 0xFF
        call SetPixel
        jmp .vert_line_up


    .vert_line_down:
        cmp rdi, r15
        je .done
        dec rdi
        mov rcx, r13
        mov rdx, rbx
        mov r8, rdi
        mov r9d, 0xFF
        call SetPixel
        jmp .vert_line_down

    ; .point_perchance:
    ;     cmp r15, rdi
    ;     jne .nvm_frown
    ;     mov rcx, r13
    ;     mov rdx, rbx
    ;     mov r8, rdi
    ;     mov r9d, 0xFF
    ;     call SetPixel

    .done:
        mov rax, r13
        pop r15
        pop r14
        pop r13
        pop r12
        pop rsi 
        pop rdi
        pop rbx
        add rsp, 48
        ret