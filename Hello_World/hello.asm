; Version 1: THIS USES A LOT OF PRECONFIGURED LIBRARIES
; This version uses the C library, which comes with a print function, handles exiting and calling the main function, which is lame, we want to do everything by
; talking with the kernel as close as possible

; bits 64
; default rel

; section .data
;     message db "Hello Woorld!", 0x0A, 0

; section .text
;     global main
;     extern printf

; main:
;     sub rsp, 40
;     lea rcx, [message]
;     call printf
;     xor rax, rax
;     add rsp, 40
;     ret


; VERSION 2: BETTER 
bits 64
default rel

section .data
    message db "Hello World!", 0x0A, 0
    ; We need the length of the string for WriteConsoleA bcs it returns the status of if it was successful or not
    ; $ takes the current rip address
    message_len equ $ - message

section .bss
    bytes_written resq 1

section .text
    global main
    extern GetStdHandle
    extern WriteConsoleA
    ; Now we use ExitProcess here, even while it is a Windows API and we are technically not interacting with the kernel directly, we can with NtTerminateProcess 
    ; The only caveat with using that is that it is way more harsh than ExitProcess, ExitProcess will gracefully close all DLLs, flush memory buffers, etc.
    ; Using NTTerminateProcess will just immedieatly shut down the program, like a force-quit, so active DLLs will not have the chance to clean up, which
    ; can lead to any data in the DLL's memory buffer can be corrupted or forever lost. So ExitProcess does use this, but makes sure everything is cleaned first
    ; Going further, we can use syscall, and feed the specific number (In windows 11s case, 0x2C) that tells the system to take the program out of memory, HOWEVER!!
    ; This number can change from update to update, so instead, using ExitProcess 
    extern ExitProcess
    extern NtTerminateProcess

main:
    sub rsp, 40

    ; Feeding -11 into GetStdHandle returns the standard output handle (STD_OUTPUT_HANDLE)
    ; The standard output handle points to za exact console or terminal session that launched za program
    mov rcx, -11
    call GetStdHandle

    ; This can be changed to be lower-level just like how we exit the process later, however it requires like 9 arguments
    ; I am lowk not tryna do allat, but it is very similar, WriteConsoleA calls NtWriteFile (which is in the same file as NtTerminateProcess: ntdll.dll)
    ; and then NtWriteFile does a syscall with specific arguments to output shebang
    mov rcx, rax
    lea rdx, [message]
    mov r8d, message_len
    lea r9, [bytes_written]
    mov qword [rsp + 32], 0
    call WriteConsoleA

    
    ; To not use the C library, we cannot use simple ret, as now we are no longer being called by the C library, 
    ; but the soon to be created .exe file will be handed to the operating system, give it to the kernel, and will run straight from the kernel.
    ; Therefore, there is no "call" from another function, this means the CPU doesn't push the return address.
    ; Since we do not have the return address, we cannot blindly use "ret", before we could because the C library would call the main(), and allow us to return whatever,
    ; and the library would handle exiting (not terminating!) the program, but if we blindly use "ret", we jump to either a random address that either doesn't exist, 
    ; or is out of the scope of this program, which causes in an exit code like -1073741819, this exit means Windows Access Violation exception. 
    ; This means the program attempted to read, write, or execute an invalid or protected memory address, causing to immediately terminate the process
    ; And so we set rcx to 0 to indicate everything went well (we would put 1 or 2 to indicate memory error, or sum other bs), and call exitprocess, a windows API
    ; Below are options of terminating a process


        ; OPTION 1:
        ; ENDING USING syscall, MOST BRUTEFORCE AND LOW-LEVEL WAY - Doing this is risky because as said before, the syscall arguments can change from windows update to update
        ; -1 in r10 is a pseudo-handle for NtCurrentProcess(), so it points to the current process, you cannot put 0 here as it will try to terminate a 0/NULL handle 

    xor edx, edx
    mov r10, -1
    mov eax, 0x2C
    syscall

        ; OPTION 2:
        ; ENDING USING NtTerminateProcess, also bruteforce as it completely cuts off the memory as stated above in the externs
        ; Using this also requires the -lntdll flag, as you have to link the specific library when compiling
        ; I should emphasize the "when compiling part", when making both the above option and below option active, you would expect the below one to not run, 
        ; but an error is still thrown, this is because when compiling, *without* the flag, the linker will see that call and not know where to find that function,
        ; even though it will never touch it. 
        ; Using this is a bit better than before, as we don't have to find the specific number for terminating a process, this call api basically
        ; implements the above option but embeds the correct number always without looking for the specific argument number (which isnt even officially documented) 
        ; putting 0 here for process handle arg (rcx) won't look for a null handle but rather kill all other threads in the process except the one executing the code 
    
    ; mov rcx, -1
    ; xor rdx, rdx
    ; call NtTerminateProcess 

        ; OPTION 3:
        ; ENDING USING ExitProcess, the best way in terms of safety, Windows API handles everything in terms of cleanly flushing DLL's and such
        ; Basically implements the above option (no need for specifying process handle), but once again, does extra stuff before calling ntTerminateProcess like cleaning up

    ; xor rcx, rcx
    ; call ExitProcess

    ; Extra info
    ; There are things called rings, and they are places for code is kept, with specific restrictions
    ; for example ring 3, which is "user mode", essentially almost all applications run here, kernel32.dll, user32.dll, and cannot directly touch hardware, or allocate memory
    ; however ring 0, which is called "kernel mode" is the core of windows, has stuff like device drivers, file systems, ntoskrnl.exe, code running here has no restrictions
    ; Code running in ring 3 cannot just jump to ring 0, however, using stuff like syscall we can
    ; ntdll.dll, the file we use to print and exit, is the lowest level library in ring 3, and acts like a wrapper for syscall instructions, 
    ; and when executing a syscall, the CPU immedieatly switches from ring 3 to 0, so the file is kinda like a bridge from ring 3 to 0
    ; THIS IS WHY, when we were getting the standard output handle, the function getStdHandle doesn't need ntdll, because it never needs to go into ring 0,
    ; the work to find the std output handle was already done by the kernel when the program starts, and is readily there waiting to be used in user space