Reason why InvalidateRect was bugging the program:
when calling that function, it causes for the entire client area (the window), to be invalid, and so a bunch of WM_Paint calls will go to the queue, taking up a bunch of CPU power,
this results in the same pixel being drawn many times, and also struggling to trigger the timer, so in our other two ways, we didnt use invalidateRect at all, and rather just 
set the pixels using the timer call, or you cna use begin/endpaint calls, which properly validate the area once done, which is the way u are SUPPOSED to do it 

Initially was using 4 individual bytes to store information on which key is pressed, not only is that a waste of a lot of space, its harder to see if all keys are not pressed, so instead we can use a single byte as a bitmask, where each bit/number on means a key is on, like 0001 is w and 0100 is s, or 0101 is g yk  

; mov r8, rsi 
; imul r8, 12
; mov eax, [f_coords + r8 + rbx*4]
; dec eax
; imul eax, 12
; mov ecx, [v_coords + eax]
; mov r9, rbx
; imul r9, 12
; mov [third_array + r9], ecx

; mov ecx, [v_coords + eax + 4]
; mov [third_array + r9 + 4], ecx

; mov ecx, [v_coords + eax + 8]
; mov [third_array + r9 + 8], ecx

; inc rbx
; cmp rbx, 3
; jne .again
; mov rbx, 0

; call to_screen

