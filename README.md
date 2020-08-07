# Disassembler
Motorola Solutions 68K

Program Specification
“A disassembler scans a section of memory and attempts to convert the memory’s contents to a listing of valid assembly language instructions. Most disassemblers cannot recreate symbolic, or label information” (CSS 422 Project Overview).
Our I/O philosophy starts with asking the user for a starting address, we first read the string input using trap task #2 from the keyboard and store it in D0. Then, we would branch into the CONVERT_STRING_TO_HEX subroutine where we would check if that char is in valid range (0-9 and A-F in ASCII = 30-39 and 41-46 in hex). If the character is greater than 46, we branch into INVALID_INPUT. We subtract 30 from 39-30 to retrieve numbers 0-9 and subtract 37 from 41 to retrieve A-F. If the user attempts to enter an address larger than the starting, an invalid output will be shown.
To begin describing our Opcode philosophy -- we load the first 4 hexabits into D3 before comparing the first hexabit. For example, LEA/JSR/RTS instructions start with ‘4’. Therefore, we will branch into the root subroutine. From there, we would check for slight differences between each via the “CMP.B” function before officially printing it to the console.
