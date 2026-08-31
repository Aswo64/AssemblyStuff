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
extern CreateCompatibleDC
extern CreateCompatibleBitmap
extern SelectObject
extern DeleteDC
extern BitBlt
extern PatBlt
extern AdjustWindowRectEx

; 658x520 = 640x480 bcs of window borders and title bar

section .data
    window_class_name db "MyWin64Class", 0
    window_title      db "za windows", 0
    mouse_raw_input_device:
        dw 1
        dw 2
        ; The value 256 is for the inputsink flag, basically allows for the input to go to the window even if it is not focused 
        dd 256
        dq 0
    pixel_x         dq 0
    pixel_y         dq 0
    wnd_length      dd 0
    wnd_width       dd 0
    keys_on       db 0
    window_size:
        dd 0
        dd 0
        dd 620
        dd 480
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
    backbuffer_dc      resq 1
    backbuffer_bitmap  resq 1
    old_bitmap         resq 1
    

section .text
global main
main:
    push rbp
    mov rbp, rsp
    sub rsp, 96

    ; Uses a windows API to change the window size to make the client area what i actually want, the borders and titles mess it up so this fixes it, however if i want to change to fullscreen, i have to change it
    ; bcs then the values given will acc be the client area
    lea rcx, [window_size]
    mov edx, 0x10CF0000
    xor r8d, r8d
    xor r9d, r9d
    call AdjustWindowRectEx

    ; Actually calculating and putting the values in memory 
    mov eax, [window_size + 8]
    sub eax, [window_size + 0]
    mov [wnd_length], eax

    mov edx, [window_size + 12]
    sub edx, [window_size + 4]
    mov [wnd_width], edx

    mov rdi, wnd_class
    xor rax, rax
    mov rcx, 10
    rep stosq

    ; Setting up the window class
    mov dword [wnd_class], 80
    mov dword [wnd_class + 4], 3
    
    lea rax, [window_procedure]
    mov qword [wnd_class + 8], rax

    lea rax, [window_class_name]
    mov qword [wnd_class + 64], rax

    ; This gives the class a black brush
    mov ecx, 4
    call GetStockObject
    mov [wnd_class+48], rax

    lea rcx, [wnd_class]
    call RegisterClassExA

    xor rcx, rcx
    lea rdx, [window_class_name]
    lea r8, [window_title]
    mov r9d, 0x10CF0000
    

    mov dword [rsp + 32], 640
    mov dword [rsp + 40], 350
    mov eax, [wnd_length]
    mov dword [rsp + 48], eax
    mov eax, [wnd_width]
    mov dword [rsp + 56], eax
    mov qword [rsp + 64], 0
    mov qword [rsp + 72], 0
    mov qword [rsp + 80], 0
    mov qword [rsp + 88], 0
    call CreateWindowExA
    mov [hwnd], rax
    
    
    ; Making a new DC and bitmap to draw on, for later drawing, here we make a DC, which is like a header for a bitmap, the new DC refers to the already existing Window DC
    ; because it basically copies the window DC settings
    ; Then we make the bitmap, and link the just made DC with the bitmap 
    mov rcx, [hwnd]
    call GetDC
    mov r15, rax

    mov rcx, r15
    call CreateCompatibleDC
    mov [backbuffer_dc], rax

    mov rcx, r15
    mov edx, 640
    mov r8d, 480
    call CreateCompatibleBitmap
    mov [backbuffer_bitmap], rax

    mov rcx, [backbuffer_dc]
    mov rdx, [backbuffer_bitmap]
    call SelectObject
    mov [old_bitmap], rax

    mov rcx, [hwnd]
    mov rdx, r15
    call ReleaseDC

    mov rcx, [hwnd]
    mov edx, 5
    call ShowWindow

    ; Registering the mouse as a raw input device, this is so we can get the mouse movement even if the mouse is outside or not focused on the window
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
    cmp rdx, 0x0100
    je key_down
    cmp rdx, 0x0101
    je key_up

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
    ; [rsp + 80]  = HWND
    ; [rsp + 88]  = window HDC
    ; [rsp +112]  = PAINTSTRUCT (72 bytes)
    ; [rsp + 32..64] are for wtvs

    sub rsp, 192

    mov [rsp + 80], rcx
    lea rdx, [rsp + 112]
    call BeginPaint
    mov [rsp + 88], rax


    mov rcx, [backbuffer_dc]
    xor edx, edx
    xor r8d, r8d
    mov r9d, [wnd_length]
    mov eax, [wnd_width]
    mov dword [rsp + 32], eax
    mov dword [rsp + 40], 0x00000042       ; BLACKNESS
    call PatBlt



    mov rax, [backbuffer_dc]
    mov rcx, 620
    mov rdx, 480
    mov r8, [pixel_x]
    mov r9, [pixel_y]
    call draw_line


    mov rcx, [rsp + 88]
    xor edx, edx
    xor r8d, r8d
    mov r9d, [wnd_length]
    mov eax, [wnd_width]
    mov dword [rsp + 32], eax
    mov rax, [backbuffer_dc]
    mov qword [rsp + 40], rax
    mov qword [rsp + 48], 0
    mov qword [rsp + 56], 0
    mov dword [rsp + 64], 0x00CC0020       ; SRCCOPY
    call BitBlt


    mov rcx, [rsp + 80]
    lea rdx, [rsp + 112]
    call EndPaint

    add rsp, 192
    xor eax, eax
    leave
    ret



key_down:
    cmp r8, 0x57
    je .w_pressed
    cmp r8, 0x53
    je .s_pressed
    cmp r8, 0x41
    je .a_pressed
    cmp r8, 0x44
    je .d_pressed

    jmp .done

    .w_pressed:
        or byte [keys_on], 00000001b
        jmp .done

    .s_pressed:
        or byte [keys_on], 00000010b
        jmp .done

    .a_pressed:
        or byte [keys_on], 00000100b
        jmp .done

    .d_pressed:
        or byte [keys_on], 00001000b
        jmp .done
        
    .done:
        leave 
        ret

key_up:
    cmp r8, 0x57
    je .w_pressed
    cmp r8, 0x53
    je .s_pressed
    cmp r8, 0x41
    je .a_pressed
    cmp r8, 0x44
    je .d_pressed

    jmp .done

    .w_pressed:
        and byte [keys_on], 11111110b
        jmp .done

    .s_pressed:
        and byte [keys_on], 11111101b
        jmp .done

    .a_pressed:
        and byte [keys_on], 11111011b
        jmp .done

    .d_pressed:
        and byte [keys_on], 11110111b
        jmp .done
        
    .done:
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
        ; Including this skip will stop rendering for the mouse movement, will still change the bitmap in the back tho
        cmp byte [keys_on], 0
        je .skip

        test byte [keys_on], 00000001b
        jz .forward
        dec qword [pixel_y]
    .forward:
        test byte [keys_on], 00000010b
        jz .back
        inc qword [pixel_y]
    .back:
        test byte [keys_on], 00000100b
        jz .left
        dec qword [pixel_x]
    .left:
        test byte [keys_on], 00001000b
        jz .continue
        inc qword [pixel_x]




    .continue:
        mov rcx, [hwnd]
        xor rdx, rdx
        mov r8, 0
        call InvalidateRect
        mov rcx, [hwnd]
        call UpdateWindow
    .skip:

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