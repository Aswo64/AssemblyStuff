Reason why InvalidateRect was bugging the program:
when calling that function, it causes for the entire client area (the window), to be invalid, and so a bunch of WM_Paint calls will go to the queue, taking up a bunch of CPU power,
this results in the same pixel being drawn many times, and also struggling to trigger the timer, so in our other two ways, we didnt use invalidateRect at all, and rather just 
set the pixels using the timer call, or you cna use begin/endpaint calls, which properly validate the area once done, which is the way u are SUPPOSED to do it 

Initially was using 4 individual bytes to store information on which key is pressed, not only is that a waste of a lot of space, its harder to see if all keys are not pressed, so instead we can use a single byte as a bitmap, where each bit/number on means a key is on, like 0001 is w and 0100 is s, or 0101 is g yk  



had to change the architecture of how i display objects, originally i had it so it would draw triangles each iteration, every iteration throught the face coords wi=ould take those three coordinates and display them at once, this makes clipping EXTREMELY hard, while its cool and probably a bit more intuitive to draw triangles instead of individual lines, it makes checking the states of each triangle much much more harder, as if a triangle is behind the camera (z<0.01), there would be 3 possible points that could be in front or behind, meaning 2^3 possible states (1 2 behind, 3 front, or 1 3 front, 2 behind, etc), which is 8, thats a lot to check, whereas if it was a line, it would be 2^2, 4 states, all in front, all behind, 1 front 2 behind, 2 front 1 behind. Not only is that a lot of states to check, i then have to find the intersection between the z-plane differently in each state. Looping through the f coords will be a bit harder but the trade-off is so worth it, 4 less states to check, I actually did try seeing how looping through the triangle would be, and came up with something like this, where i use a bitmap, because not only would i have to figure out the state of each point in that triangle, i would have to communicate that to the drawing algorithm, since i would give the entire triangle and tell it to draw it, that bitmap would have to tell the drawing algorithm, "only draw these".  

; ; x
; movss xmm0, [third_array]
; ; y
; movss xmm1, [third_array + 4]
; ; z
; movss xmm2, [third_array + 8]


; movss xmm3, [pixel_x]
; addss xmm0, xmm3


; movss xmm3, [pixel_y]
; addss xmm2, xmm3

; ; rotating x axis must be done first to make it natural, why? idk search it up
; call rotatey
; call rotatex

; ucomiss xmm2, [z_plane]
; jg .continue
; ; 1 behind, 2 3 unknown
; movss [rsp], xmm0
; movss [rsp + 4], xmm1
; movss [rsp + 8], xmm2

; ; other point's z coord
; movss xmm0, [third_array + 12]
; movss xmm1, [third_array + 16]
; movss xmm2, [third_array + 20]
; movss xmm3, [pixel_y]
; addss xmm2, xmm3

; call rotatey
; call rotatex

; ucomiss xmm2, [z_plane]
; jg .yikers
; ; 1 2 behind, 3 unknown
; movss [rsp + 12], xmm0
; movss [rsp + 16], xmm1
; movss [rsp + 20], xmm2

; ; other other point's z coord
; movss xmm0, [third_array + 24]
; movss xmm1, [third_array + 28]
; movss xmm2, [third_array + 32]
; movss xmm3, [pixel_y]
; addss xmm2, xmm3
; call rotatey
; call rotatex

; ucomiss xmm2, [z_plane]
; jg .nvmugood
; ; all three are behind
; mov byte [points_valid], 0
; ret
; .nvmugood:
; ; 1 2 behind, 3 in front
; mov byte [points_valid], 0001b
; ret


; .yikers:
; ; 1 behind, 2 in front, 3 unknown
; ; other other point's z coord
; movss [rsp + 12], xmm0
; movss [rsp + 16], xmm1
; movss [rsp + 20], xmm2

; movss xmm0, [third_array + 24]
; movss xmm1, [third_array + 28]
; movss xmm2, [third_array + 32]
; movss xmm3, [pixel_y]
; addss xmm2, xmm3
; call rotatey
; call rotatex

; ucomiss xmm2, [z_plane]
; jg .justone
; ; 1 3 behind, 2 in front
; mov byte [points_valid], 0010b
; ret


; .justone:
; ; 1 behind, 2 3 in front
; mov byte [points_valid], 0011b
; ret





; .continue:
; ; 1 in front, 2 3 unknown


; ; x / z
; divss xmm0, xmm2
; ; y / z
; divss xmm1, xmm2

; ; fitting to viewport
; addss xmm0, [one]
; mulss xmm0, [half]

; addss xmm1, [one]
; mulss xmm1, [half]
; movss xmm3, [one]
; subss xmm3, xmm1
; movss xmm1, xmm3

; cvtsi2ss xmm3, dword [window_size+8]
; cvtsi2ss xmm4, dword [window_size+12]

; mulss xmm0, xmm3
; mulss xmm1, xmm4

; cvtss2si eax, xmm0
; cvtss2si ecx, xmm1




; mov dword [triangle], eax
; mov dword [triangle + 4], ecx


Upon finding that it was hard to calculate the z-plane intersection without using memory (i was trying to see if i could calculate everything entirely using registers, as that would vastly improve computation speed and reduce the amount of cycles), I realized that floats are 128 bits, and i was storing single precision floats, meaning i could store 4 floats inside one single float register, originally I was putting a single float inside a single float register, this was such a waste of space and i changed my code to utilize this.