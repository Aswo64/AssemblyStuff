Reason why InvalidateRect was bugging the program:
when calling that function, it causes for the entire client area (the window), to be invalid, and so a bunch of WM_Paint calls will go to the queue, taking up a bunch of CPU power,
this results in the same pixel being drawn many times, and also struggling to trigger the timer, so in our other two ways, we didnt use invalidateRect at all, and rather just 
set the pixels using the timer call, or you cna use begin/endpaint calls, which properly validate the area once done, which is the way u are SUPPOSED to do it 

