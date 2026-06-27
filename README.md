# AssemblyStuff
working w/ assembly
Made these programs after reading https://github.com/mschwartz/assembly-tutorial#alu
- Learned the architecture of a cpu and how it interacts with memory
- Learned how the CPU will use the MMU to allocate virtual memory for processes, making it think it has x amount of memory when it actually does not yet, further helped me understand the point of "aligning" in assembly
- Learned how an assembler will compile assembly to create object files, files that convert human code into  machine code (binary), and a linker will turn it into an ELF file that can be executed, the ELF file is split into parts, .text, the actual code and shi, .data, initialized data (not to be confused with the heap, .data has a fixed sized and it determined at compile time, the heap changes and fluctuates, the heap is stored on the RAM, not the ELF file), .rodata, read only data, .bss, non-initialized data
- Learned about Prologue and Epilogue, and the types of registers, specifically the special purpose ones such as RIP, RSP, and how some have specific purposes but can be used for general purpose:
Below 3 lines are called the prologue:
- push rbp
- mov rbp, rsp
- sub rsp, 16

Rbp is sometimes omitted (called frame pointer omission, and makes it harder to debug), rbp makes it easier to find local variables and arguments since rbp is static/fixed during functions, unlike rsp which moves a lot. That doesn't mean its impossible to use rsp for finding the same variables and arguments, just a bit harder, but it helps with efficiency, using rbp for other purposes is better as you now have a whole other register you can use for general purpose. Using registers instead of memory is way way more efficient, registers are physical units inside the CPU, whereas memory is physically far away and all the way on the RAM, taking up to 200 times more time for data to travel if you use RAM.


- add ebp-4,8,12, edi

These have inputs and stuff/parameters IF we are in 32 bit (using eax, edi, and shi), if we are in 64-bit (using rax, rdi, and shi), we have 7 argument parameters, when using 32-bit, we have half the registers, and so we do not have many argument parameters, the arguments will then go to stack, the order of calling a function is no longer just the return address, it is the arguments, and then the return address, so rbp-4 is first argument, rbp-8 is second argument, and so on.

- Understood what pages, segfaults, macros are and the process of calling functions and getting external libraries
- Learned conditionals for assembly, not je but %if from %assign, good for determining the code before it runs/while it compiles, good for checking stuff before it runs 
- Understood how to reserve bytes in order to make variables or structs 
