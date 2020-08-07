# Disassembler
Motorola Solutions 68K

Program Specification
“A disassembler scans a section of memory and attempts to convert the memory’s contents to a listing of valid assembly language instructions. Most disassemblers cannot recreate symbolic, or label information”.

Our I/O philosophy starts with asking the user for a starting address, we first read the string input using trap task #2 from the keyboard and store it in D0. Then, we would branch into the CONVERT_STRING_TO_HEX subroutine where we would check if that char is in valid range (0-9 and A-F in ASCII = 30-39 and 41-46 in hex). If the character is greater than 46, we branch into INVALID_INPUT. We subtract 30 from 39-30 to retrieve numbers 0-9 and subtract 37 from 41 to retrieve A-F. If the user attempts to enter an address larger than the starting, an invalid output will be shown.
To begin describing our Opcode philosophy -- we load the first 4 hexabits into D3 before comparing the first hexabit. For example, LEA/JSR/RTS instructions start with ‘4’. Therefore, we will branch into the root subroutine. From there, we would check for slight differences between each via the “CMP.B” function before officially printing it to the console.

To maintain reusability in our code, we simply invented mini subroutines to analyze all 12 bits behind the first four hexabits. For each 3 bits, we equate it to addresses ranging from 350 to 500. The first three bits after the 4 hexabits in front are labeled as ‘FIRST_THREE_BITS_IN_TWELVE_BITS EQU $350, SECOND_THREE_BITS_IN_TWELVE_BITS EQU $400, THIRD_THREE_BITS_IN_TWELVE_BITS EQU $450 etc. Depending on what we are trying to extract from the 3 bits, we can easily use LSR/LSL to isolate specific bits for comparison. Since we pre-made subroutines, we are able to concentrate more on the logic behind instructions instead of shifting bits around.

Our EA philosophy mainly relies on a  few key JMP tables namely :- OUTPUT_SOURCE/PRINT_DESTINATION/DERIVING_OPCODES  which assists in scanning thoroughly for effective mode/effective address/destination mode/destination register. To start comparing, we move the targeted set number of bits (1st/2nd/3rd/4th) into D3 before entering with JSR OUTPUT_SOURCE. For instructions that do not require destination registers, we are able to print the output address registers directly without interfering with bit shifting.
Any unrequired opcodes or an unexisting instruction will branch into ‘OPCODE_IS_INVALID”. When opcode is invalid (for example, ADD.W #$1234,D1 (0641 1234) this will be printed out as: *DATA $WXYZ where $WXYZ is the hexadecimal number that couldn't be decoded, so that the program can continue.

Furthermore, our program only prints 20 instructions per screen-- it enables the user to press any key to assemble the next 20 instructions until there is none left. After successfully assembling the instructions, a user can enter ‘yes’ for more decoding or ‘no’ to exit the program completely. Else, we end the program with DATA $FFFF indicating that there is no more data to be disassembled.
 
 
 
