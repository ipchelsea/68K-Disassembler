*-----------------------------------------------------------
* Title      : CSS 422 Disassembler Project
* Written by : Yun Jae Cho, Marcela Gomez and Chelsea Ip
* Date       : May 30th 2020
* Description:
*-----------------------------------------------------------
STACK EQU $B000
FOUR_HEXABITS_IN_MEMORY  EQU $300
FIRST_THREE_BITS_IN_TWELVE_BITS EQU $350
SECOND_THREE_BITS_IN_TWELVE_BITS EQU $400
THIRD_THREE_BITS_IN_TWELVE_BITS EQU $450
FOURTH_THREE_BITS_IN_TWELVE_BITS EQU $500
STORAGE_VAR EQU $550


START ORG $1000
    LEA STACK,SP *set up stack pointer
    
ASK_STARTING_ADDRESS
    LEA STARTING_MESSAGE, A1 *put address of startinge_message to A1
    MOVE #14, D0             *display Null terminated string at (A1) without CR, LF
    TRAP #15                 *print the starting messsage
    MOVEA.L #0,A1            *clear contents in A1 for the case ASK_STARTING_ADDRESS is called again
    
    MOVE.W #2,D0             *read string input from keyboard and store at (A1)
    TRAP #15 
    BRA CONVERT_STRING_TO_HEX
 
ASK_ENDING_ADDRESS
    LEA ENDING_MESSAGE, A1 *put address of startinge_message to A1
    MOVE #14, D0             *display Null terminated string at (A1) without CR, LF
    TRAP #15                 *print the starting messsage
    MOVEA.L #0,A1            *clear contents in A1 for the case ASK_STARTING_ADDRESS is called again
    
    MOVE.W #2,D0             *read string input from keyboard and store at (A1)
    TRAP #15 
    BRA CONVERT_STRING_TO_HEX    
    
CONVERT_STRING_TO_HEX
    MOVE.B (A1)+, D0    *put one character from the user input string into D0
    CMP.B #$46, D0      *check if that char is in valid range (0-9 and A-F in ASCII = 30-39 and 41-46 in hex)
    BGT INVALID_INPUT   *If the char is bigger than $46, it's invalid
    CMP.B #$41, D0
    BLT CONVERT_ZERO_TO_NINE_TO_HEX *If the char is less than $41, let CONVERT_ZERO_TO_NINE_TO_HEX deal with it
    
    SUB.B #$37, D0      *if it is here, it means the char is between A-F(41-46), -37 to get A-F
    ADD.L D0,D3         
    SUBI #1,D1          *trap task 2: length of input is retuned in D1.W
    CMP.B #0,D1         *check if length is 0 
    BEQ DONE_CONVERTING_STARTING_STR *if length becomes 0, it means no more character to convert to hex
    LSL.L #4,D3
    BRA CONVERT_STRING_TO_HEX   
    
    
CONVERT_ZERO_TO_NINE_TO_HEX
    CMP.B #$39, D0       *if bigger than $39 and smaller than 41 it means invalid 
    BGT INVALID_INPUT   
    CMP.B #$30, D0       *if smaller than 30 it is also invalid
    BLT INVALID_INPUT
    SUB.B #$30,D0        *subtract 30 to get 0-9
    ADD.L D0,D3
    SUBI #1,D1
    CMP.B #0,D1
    BEQ DONE_CONVERTING_STARTING_STR
    LSL.L #4,D3
    BRA CONVERT_STRING_TO_HEX

INVALID_INPUT
    LEA INVALID_INPUT_MESSAGE, A1 *put address of invalid_input_message to A1
    MOVE #14, D0                  *display Null terminated string at (A1) without CR, LF
    TRAP #15                      *print the starting messsage
    CLR D3    
    BRA ASK_STARTING_ADDRESS      *ask starting address again
   

DONE_CONVERTING_STARTING_STR
    CMP #1,D5
    BEQ DONE_CONVERTING_ENDING_STR
    ADDI #1,D5
 
    MOVEA.L D3, A3
    CLR D3
    
    BRA ASK_ENDING_ADDRESS
    
        
DONE_CONVERTING_ENDING_STR
    CLR.W D5
    MOVEA.L D3, A4 *PUT TO A4
    CLR D3
    BRA  START_TO_HANDLE_OPCODE *continued from here after report2

START_TO_HANDLE_OPCODE
    JSR IS_NEW_SCREEN_NEEDED
    BRA DERIVING_OPCODE
    	
DERIVING_OPCODE
    LEA    STR_SPACE,A1 *print a new line
    MOVE.B #13,D0
    TRAP   #15
    
    JSR PRINT_MEMORY_ADDRESS
    JSR GET_NEXT_WORD
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR SAVE_FIRST_HEX_IN_D3  
    CMP.B #$0D,D3
    BEQ OPCODE_IS_ADD
    CMP.B #$0B,D3
    BEQ OPCODE_IS_CMP
    CMP.B #$08,D3
    BEQ OPCODE_IS_OR
    CMP.B #$09,D3
    BEQ OPCODE_IS_SUB
    CMP.B #$0C,D3
    BEQ OPCODE_IS_AND
    CMP.B #$01,D3
    BEQ OPCODE_IS_MOVEB
    CMP.B #$03,D3
    BEQ OPCODE_IS_MOVEW_OR_MOVEAW
    CMP.B #$02,D3
    BEQ OPCODE_IS_MOVEL_OR_MOVEAL
    CMP.B #$06,D3
    BEQ OPCODE_IS_BCC_BGT_BLE
    CMP.B #$4,D3 *LEA/JSR/RTS/MOVEM
    BEQ OPCODE_IS_4
    CMP.B #$0E,D3
    BEQ OPCODE_STARTS_WITH_E *LSL/ASR
    
    JSR OPCODE_IS_INVALID
	
    SIMHALT             ; halt simulator
    
*-----------------------------------------------------------
*                   OPCODE_STARTS_WITH_E
*-----------------------------------------------------------
* DERIVING_OPCODE -There is register shift/memory shift for both LSL and ASR.
* LSL (REGISTER SHIFT)--> 1110 [REG] DR SIZE i/r 01 [REG]
* LSL (MEMORY SHIFT)--> 1110001 DR 11 [EA MODE] [EA REG]
* ASR (REGISTER SHIFT) --> 1110 [REG] DR SIZE i/r 00 [REG]
* ASR (MEMORY SHIFT) --> 1110000 DR 11 [EA MODE] [EA REG]

* IF YOU ARE COMPARING LSL IN REGISTER SHIFT, COMPARE 01 AND 00 BEFORE [REG]
* IF YOU ARE COMPARING LSL TO ASR IN MEMORY SHIFT, LOOK AT THE LAST HEXABITS OF THE FIRST 3

* To identify the "WORD" value, we would need to create a memory shift test 

* -----------------------SYNTAX----------------------------
* LSd Dx,Dy 
* LSd #<data>,Dy 
* LSd <ea> 
*-----------------------------------------------------------
* ASd Dx,Dy 
* ASd #<data>, Dy 
* ASd <ea>
*-----------------------------------------------------------
OPCODE_STARTS_WITH_E 
	
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Load the first four hex into D3
	JSR ANALYZE_TWELVE_BITS *Analyze the 12 bits, here we are dividing
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3  *Analyze the second three bits of the 12 bits
	LSL.B #6,D3 *Isolate 6th and 7th bit to check if memory register is 1
    LSR.B #6,D3            
	CMPI.B #%11, D3 
	BEQ IS_MEM_SHIFT_OR_ABSOLUTE *Check if it is a LSL or ASR memory shift type OR LSL $/ASR $
	
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Load back the first four hexabits into D3
	MOVE.W THIRD_THREE_BITS_IN_TWELVE_BITS, D3 
	LSL.B #6,D3
    LSR.B #6,D3 * Isolate the size bits (again) for register shift opcode type
    CMP.B #%00,D3 *This is ASR REGISTER SHIFT
	BEQ IS_ASR_REGISTER_SHIFT_OR_IMM
	CMP.B #%01,D3 *LSL Data Register
	BEQ IS_LSL_REGISTER_SHIFT_OR_IMM *#$ LSL
	
	BRA OPCODE_IS_INVALID
	RTS

*-----------------------------------------------------------
* IS_ASR_REGISTER_SHIFT_OR_IMM
* ASd Dx,Dy 
* ASd # < data > ,Dy 
*-----------------------------------------------------------	
IS_MEM_SHIFT_OR_ABSOLUTE
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Load first four hex
	MOVE.W THIRD_THREE_BITS_IN_TWELVE_BITS, D3 *Analyze third three bits
	CMP.W #%111, D3 *Compare LSL or ASR absolute address
	BEQ IS_LSL_OR_ASR_ADDRESS	
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
	MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, D3
	CMP.B #%000,D3 *Check 9th bit to 11 bit to see if it hits 000 or 001
    BEQ  IS_ASR_MEMORY_REGISTERS *ASR
    CMP.B #%001,D3 *LSL 
    BEQ  IS_LSL_MEMORY_REGISTERS
	RTS

*-----------------------------------------------------------
* IS_LSL_OR_ASR_ADDRESS
*  LSd # <data> ,Dy 
*-----------------------------------------------------------	
IS_LSL_OR_ASR_ADDRESS	*How to differentiate between LSL and ASR
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3   *Load first four hex into D3 again to analyze
	MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, D3  *Analyze first three bits
	CMP.W #%000,D3 *Check 9th bit to 11 bit to see if it hits 000 or 001
    BEQ  IS_ASR_ADDRESS_ONLY *ASR
    CMP.W #%001,D3 *LSL 
    BEQ IS_LSL_ADDRESS_ONLY
    BRA START_TO_HANDLE_OPCODE
    BRA OPCODE_IS_INVALID
    RTS

	
*-----------------------------------------------------------
* Figure out how to print long word data or word data
*  LSR.W $12
*-----------------------------------------------------------	
IS_LSL_ADDRESS_ONLY
	LEA STR_LSL, A1 *PRINTS ASR
	MOVE.B #14, D0
	TRAP #15
	
	JSR PRINT_DOT
	JSR PRINT_WORD_SIZE *PRINTS WORD SIZE
	JSR PRINT_SPACE
	
	LEA STR_HEX, A1 *PRINTS $
	MOVE.B #14, D0
	TRAP #15
	
	BRA HEPLER_LSL_AND_ASL_ADDR *PRINTS ADDRESS REGISTERS HERE
	BRA DERIVING_OPCODE
	RTS
		

*-----------------------------------------------------------
* IS_ASR_ADDRESS_ONLY
*  Figure out how to print long word data or word data
*  LSR.W $12
*-----------------------------------------------------------		
IS_ASR_ADDRESS_ONLY *ASR
	LEA STR_ASR, A1 *PRINTS ASR
	MOVE.B #14, D0
	TRAP #15
	
	JSR PRINT_DOT
	JSR PRINT_WORD_SIZE *PRINTS WORD SIZE
	JSR PRINT_SPACE
	
	LEA STR_HEX, A1 *PRINTS $
	MOVE.B #14, D0
	TRAP #15
	
	BRA HEPLER_LSL_AND_ASL_ADDR *PRINTS ADDRESS REGISTERS HERE
	BRA DERIVING_OPCODE
	RTS

*-----------------------------------------------------------
* Figure out how to print long word data or word data
*  LSR.W $12
*-----------------------------------------------------------	
HEPLER_LSL_AND_ASL_ADDR 
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Load first four hex
	MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, D3 *Analyze third three bits
	JSR SECONDSECTION *Here you will detect whether to print word or longword data
	BRA START_TO_HANDLE_OPCODE *branch back to this to derive next opcode
	RTS

*-----------------------------------------------------------
* IS_ASR_REGISTER_SHIFT_OR_IMM
*-----------------------------------------------------------	
IS_ASR_REGISTER_SHIFT_OR_IMM
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Load first four hex
	MOVE.W THIRD_THREE_BITS_IN_TWELVE_BITS, D3 *Analyze third three bits
	CMP.W #%000, D3 *If 000, then you know it'll be an ASR #$
	BEQ VERIFY_ASR_IMM_DATA
	CMP.W #%100, D3 *If 100, then you know it'll be a register shift
	BEQ VERIFY_ASL_OR_ASR_REG
	RTS

ASR_IMM_INVALID
	LEA STR_DATA, A1 *put address of invalid_input_message to A1
    MOVE #14, D0                  *display Null terminated string at (A1) without CR, LF
    TRAP #15 
	JSR PRINT_SPACE
	LEA STR_IMM, A1
    JSR PRINT_MESSAGE_TO_CONSOLE

	LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    
    JSR HEX_TO_STRING
    JSR PRINT_SPACE
    
    BRA START_TO_HANDLE_OPCODE

	RTS	

VERIFY_ASR_IMM_DATA
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Load first four hex
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3 *Analyze third three bits
	CMP.W #%110, D3 *If 000, then you know it'll be an ASR #$
	BEQ ASR_IMM_INVALID
	CMP.W #%101, D3 *If 000, then you know it'll be an ASR #$
	BEQ ASR_IMM_INVALID
	CMP.W #%100, D3 *If 000, then you know it'll be an ASR #$
	BEQ ASR_IMM_INVALID
	BRA IS_ASR_IMMEDIATE_DATA
	BRA START_TO_HANDLE_OPCODE
	BRA OPCODE_IS_INVALID
	RTS

*-----------------------------------------------------------
* IS_ASR_IMMEDIATE_DATA
*-----------------------------------------------------------
IS_ASR_IMMEDIATE_DATA
	LEA STR_ASR, A1 *PRINTS ASR
	MOVE.B #14, D0
	TRAP #15
	JSR PRINT_DOT
	
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3 *Trying to get size here
	LSL.B #6,D3 *Isolate to only get the 6th & 7th bit
    LSR.B #6,D3    
	JSR PRINT_COMMON_SIZE_ASR_LSL
	BRA HEPLER_ASR_IMMEDIATE_DATA *Enter new helper method
	BRA DERIVING_OPCODE
	RTS

*-----------------------------------------------------------
* HEPLER_ASR_IMMEDIATE_DATA 
*-----------------------------------------------------------
HEPLER_ASR_IMMEDIATE_DATA 
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Move first 4 hexabits into D3
    JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
	JSR PRINT_SPACE

	LEA STR_IMM, A1 *Prints #
	MOVE.B #14, D0
	TRAP #15
	
	LEA STR_HEX, A1 *Prints $
	MOVE.B #14, D0
	TRAP #15
	
	CLR D3
	JSR ANALYZE_TWELVE_BITS
   	MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR *Check for the first 3 bits to print the register number
	JSR PRINT_REGISTER_NUM *Prints out the number
	
	JSR PRINT_COMMA *,
	JSR PRINT_SPACE
	
	LEA DATA_REGISTER, A1 *PRINTS D2
	MOVE.B #14, D0
	TRAP #15

	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR ANALYZE_TWELVE_BITS
    
    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
	JSR PRINT_REGISTER_NUM *PRINTS 2
	
	BRA START_TO_HANDLE_OPCODE *branch back to this to derive next opcode

	RTS

*-----------------------------------------------------------
*  IS_LSL_REGISTER_SHIFT_OR_IMMEDIATE_REGISTER
*  LSd # <data> ,Dy 
*-----------------------------------------------------------	
IS_LSL_REGISTER_SHIFT_OR_IMM
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Load first four hex
	MOVE.W THIRD_THREE_BITS_IN_TWELVE_BITS, D3 *Analyze third three bits
	CMP.W #%001, D3 *If 001, then you'll know it's LSL.B #$1, D2
	BEQ VERIFY_LSL_IMM_DATA
	BRA VERIFY_LSL_OR_LSR_REG
	RTS


LSL_IMM_IS_INVALID
    LEA STR_DATA, A1 *put address of invalid_input_message to A1
    MOVE #14, D0                  *display Null terminated string at (A1) without CR, LF
    TRAP #15 
	JSR PRINT_SPACE
	LEA STR_IMM, A1
    JSR PRINT_MESSAGE_TO_CONSOLE

	LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    
    JSR HEX_TO_STRING
    JSR PRINT_SPACE
    
    BRA START_TO_HANDLE_OPCODE

	RTS	
	
VERIFY_LSL_IMM_DATA
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Load first four hex
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3 *Analyze third three bits
	CMP.W #%000, D3 *If 001, then you'll know it's LSL.B #$1, D2
	BEQ LSL_IMM_IS_INVALID
	CMP.W #%001, D3 *If 001, then you'll know it's LSL.B #$1, D2
	BEQ LSL_IMM_IS_INVALID
	CMP.W #%010, D3 *If 001, then you'll know it's LSL.B #$1, D2
	BEQ LSL_IMM_IS_INVALID
	BRA IS_LSL_IMMEDIATE_DATA
	BRA START_TO_HANDLE_OPCODE
	BRA OPCODE_IS_INVALID
	RTS

*-----------------------------------------------------------
* IS_LSL_IMMEDIATE_DATA
*-----------------------------------------------------------
IS_LSL_IMMEDIATE_DATA
	LEA STR_LSL, A1 *PRINTS ASR
	MOVE.B #14, D0
	TRAP #15
	JSR PRINT_DOT
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3 *Trying to get size here
	LSL.B #6,D3 *Isolate to only get the 6th & 7th bit
    LSR.B #6,D3    
	JSR PRINT_COMMON_SIZE_ASR_LSL
	BRA HEPLER_LSL_IMMEDIATE_DATA *Enter new helper method
	BRA DERIVING_OPCODE
	RTS
	
*-----------------------------------------------------------
* HEPLER_LSL_IMMEDIATE_DATA 
*-----------------------------------------------------------
HEPLER_LSL_IMMEDIATE_DATA 
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Move first 4 hexabits into D3
    JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
	JSR PRINT_SPACE
	LEA STR_IMM, A1 *Prints #
	MOVE.B #14, D0
	TRAP #15
	LEA STR_HEX, A1 *Prints $
	MOVE.B #14, D0
	TRAP #15
	CLR D3
	JSR ANALYZE_TWELVE_BITS
   	MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR *Check for the first 3 bits to print the register number
	JSR PRINT_REGISTER_NUM *Prints out the number
	JSR PRINT_COMMA *,
	JSR PRINT_SPACE
	LEA DATA_REGISTER, A1 *PRINTS D2
	MOVE.B #14, D0
	TRAP #15
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR ANALYZE_TWELVE_BITS
    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
	JSR PRINT_REGISTER_NUM *PRINTS 2
	BRA START_TO_HANDLE_OPCODE *branch back to this to derive next opcode
	RTS


*-----------------------------------------------------------
* HEPLER_LSL_AND_ASL_MEMORY
*-----------------------------------------------------------
HEPLER_LSL_AND_ASL_MEMORY 
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Move first 4 hexabits into D3
    JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
	JSR PRINT_SPACE
	MOVE.W THIRD_THREE_BITS_IN_TWELVE_BITS, D3 *Check for the second last 3 bits
    JSR OUTPUT_MEMORY_REGISTERS_ONLY *problem here
 	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR ANALYZE_TWELVE_BITS
    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
    BRA START_TO_HANDLE_OPCODE *branch back to this to derive next opcode
    BRA DERIVING_OPCODE
	RTS

	
*-----------------------------------------------------------
* IS_ASR_MEMORY_REGISTERS - Only WORD Size will be used
*-----------------------------------------------------------	
IS_ASR_MEMORY_REGISTERS *CHECKING FOR LSR, NON REQUIRED INSTRUCTION
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Here we check if it equals to LSR
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3 *Check for the second last 3 bits
	CMP.W #%111, D3
	BEQ ASL_IS_INVALID
	BRA IS_ASR_PRINT_MEM_REG
	BRA START_TO_HANDLE_OPCODE
	RTS 

IS_ASR_PRINT_MEM_REG	
	LEA STR_ASR, A1  *PRINTS ASR
	MOVE.B #14, D0
	TRAP #15
	JSR PRINT_DOT
	JSR PRINT_WORD_SIZE *PRINTS WORD SIZE
	BRA HEPLER_LSL_AND_ASL_MEMORY *PRINTS ADDRESS REGISTERS HERE
	BRA START_TO_HANDLE_OPCODE
	BRA OPCODE_IS_INVALID
	RTS

ASL_IS_INVALID
    LEA STR_DATA, A1 *put address of invalid_input_message to A1
    MOVE #14, D0                  *display Null terminated string at (A1) without CR, LF
    TRAP #15 
	JSR PRINT_SPACE
	LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    
    JSR HEX_TO_STRING
    JSR PRINT_SPACE
    
    BRA START_TO_HANDLE_OPCODE

	RTS	

*-----------------------------------------------------------
* IS_LSL_MEMORY_REGISTERS
*-----------------------------------------------------------	
IS_LSL_MEMORY_REGISTERS *CHECKING FOR LSR, NON REQUIRED INSTRUCTION
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Here we check if it equals to LSR
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3 *Check for the second last 3 bits
	CMP.W #%011, D3
	BEQ LSR_IS_INVALID 
	BRA IS_LSL_PRINT_MEM_REG	
	BRA START_TO_HANDLE_OPCODE
	RTS

IS_LSL_PRINT_MEM_REG	
	LEA STR_LSL, A1 *PRINTS LSL
	MOVE.B #14, D0
	TRAP #15
	JSR PRINT_DOT
	JSR PRINT_WORD_SIZE *PRINTS WORD SIZE
	BRA HEPLER_LSL_AND_ASL_MEMORY 
	BRA START_TO_HANDLE_OPCODE
	RTS

LSR_IS_INVALID 
    LEA STR_DATA, A1 *put address of invalid_input_message to A1
    MOVE #14, D0                  *display Null terminated string at (A1) without CR, LF
    TRAP #15 
	JSR PRINT_SPACE
	LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    
    JSR HEX_TO_STRING
    JSR PRINT_SPACE
    
    BRA START_TO_HANDLE_OPCODE

	RTS	
	
    
*-----------------------------------------------------------
* OUTPUT_MEMORY_REGISTERS_ONLY 
*-----------------------------------------------------------		
OUTPUT_MEMORY_REGISTERS_ONLY *We are targeting to print the address registers at LSL.W (A1) OR LSL.W (A1)+ 
    CMPI.B #%010,D3 *(An)
    BEQ REGISTER_MODE_010_MEMORY
    CMPI.B #%011,D3 *(An)+
    BEQ REGISTER_MODE_011
    CMPI.B #%100,D3 *-(An)
    BEQ REGISTER_MODE_100
    BRA OPCODE_IS_INVALID
    RTS

REGISTER_MODE_001_MEMORY                                       
    JSR OUTPUT_ADDRESS_REGISTER	   * Print An
    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR *Try to check for last 3 bits
	JSR PRINT_REGISTER_NUM *PRINTS 2
    RTS
    
REGISTER_MODE_010_MEMORY                  * Print (An)
    LEA OPENING_PARENTHESIS, A1
    JSR PRINT_MESSAGE_TO_CONSOLE         
    JSR REGISTER_MODE_001_MEMORY		      
    LEA CLOSING_PARENTHESIS, A1
    JSR PRINT_MESSAGE_TO_CONSOLE 
    RTS

*-----------------------------------------------------------
* IS_ASR_REGISTER_SHIFT
*-----------------------------------------------------------
IS_ASR_REGISTER_SHIFT
	LEA STR_ASR, A1 *PRINTS ASR
	MOVE.B #14, D0
	TRAP #15
	JSR PRINT_DOT
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3 *Trying to get size here
	LSL.B #6,D3 *Isolate to only get the 6th & 7th bit
    LSR.B #6,D3    
	JSR PRINT_COMMON_SIZE_ASR_LSL
	BRA HEPLER_LSL_ASR_REGISTER_SHIFT
	BRA DERIVING_OPCODE
	RTS

VERIFY_ASL_OR_ASR_REG *BEFORE ENTERING IS_LSL_REGISTER SHIFT
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3
	CMP.B #%100, D3
	BEQ ASL_REG_SHIFT_IS_INVALID *Indicating RIGHT
	CMP.B #%101, D3
	BEQ ASL_REG_SHIFT_IS_INVALID *Indicating RIGHT
	CMP.B #%110, D3
	BEQ ASL_REG_SHIFT_IS_INVALID *Indicating RIGHT
	BRA IS_ASR_REGISTER_SHIFT
	BRA START_TO_HANDLE_OPCODE
	RTS		


ASL_REG_SHIFT_IS_INVALID
	LEA STR_DATA, A1 *put address of invalid_input_message to A1
    MOVE #14, D0                  *display Null terminated string at (A1) without CR, LF
    TRAP #15 
    
	JSR PRINT_SPACE
	LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    
    JSR HEX_TO_STRING
    JSR PRINT_SPACE
    
    BRA START_TO_HANDLE_OPCODE

	RTS	

*-----------------------------------------------------------
*IS_LSL_REGISTER_SHIFT
*-----------------------------------------------------------

LSR_REG_SHIFT_IS_INVALID
	LEA STR_DATA, A1 *put address of invalid_input_message to A1
    MOVE #14, D0                  *display Null terminated string at (A1) without CR, LF
    TRAP #15 
	JSR PRINT_SPACE

	LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    
    JSR HEX_TO_STRING
    JSR PRINT_SPACE
    
    BRA START_TO_HANDLE_OPCODE

	RTS	
	
	
VERIFY_LSL_OR_LSR_REG *BEFORE ENTERING IS_LSL_REGISTER SHIFT
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3
	CMP.B #%000, D3
	BEQ LSR_REG_SHIFT_IS_INVALID *Indicating RIGHT
	CMP.B #%001, D3
	BEQ LSR_REG_SHIFT_IS_INVALID *Indicating RIGHT
	CMP.B #%010, D3
	BEQ LSR_REG_SHIFT_IS_INVALID *Indicating RIGHT
	BRA IS_LSL_REGISTER_SHIFT
	RTS				

IS_LSL_REGISTER_SHIFT
	LEA STR_LSL, A1 *PRINTS LSL
	MOVE.B #14, D0
	TRAP #15
	JSR PRINT_DOT
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3 *Trying to get size here
	LSL.B #6,D3 *Isolate to only get the 6th and 7th bit
    LSR.B #6,D3    
	JSR PRINT_COMMON_SIZE_ASR_LSL
	*Inserts a comparison here to tell between normal data registers and immediate data
	BRA HEPLER_LSL_ASR_REGISTER_SHIFT
	BRA START_TO_HANDLE_OPCODE
	RTS
	
*-----------------------------------------------------------
*HEPLER_LSL_REGISTER_SHIFT WORKS
*-----------------------------------------------------------
HEPLER_LSL_ASR_REGISTER_SHIFT
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
	JSR PRINT_SPACE
	
	LEA DATA_REGISTER, A1 *PRINTS D
	MOVE.B #14, D0
	TRAP #15
	
	MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
	JSR PRINT_REGISTER_NUM *Prints 1

	JSR PRINT_COMMA
	JSR PRINT_SPACE
	
	LEA DATA_REGISTER, A1 *PRINTS D
	MOVE.B #14, D0
	TRAP #15
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR ANALYZE_TWELVE_BITS
    
    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
	JSR PRINT_REGISTER_NUM *PRINTS 2
	
	BRA START_TO_HANDLE_OPCODE *branch back to this to derive next opcode

	RTS
	
*-----------------------------------------------------------
* PRINT_COMMON_SIZE_ASR_LSL
*-----------------------------------------------------------
PRINT_COMMON_SIZE_ASR_LSL
	CMP.B #%01,D3 *WORD
  	BEQ	PRINT_WORD_SIZE
    CMP.B #%00,D3 *BYTE
  	BEQ	PRINT_BYTE_SIZE
  	BRA	PRINT_LONG_SIZE
    RTS
    

*-----------------------------------------------------------
* OPCODE_IS_4 *RTS, JSR and LEA *NOP
*-----------------------------------------------------------
OPCODE_IS_4 *RTS, JSR, LEA and MOVEM
 	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3           
    JSR SAVE_SECOND_HEX_IN_D3 
    CMP.W #%1110,D3 *Only branches into OPCODE_IS_RTS_JSR if the second hex
	BEQ OPCODE_IS_RTS_JSR 
	
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 
	JSR ANALYZE_TWELVE_BITS
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3
	CMP.W #%111, D3
	BEQ OPCODE_IS_LEA 
	JSR VERIFY_OPCODE_MOVEM        *verify 9,8,7 is 001
    
*    BRA OPCODE_IS_INVALID  ****this line causeing extra DATA to print
*	RTS



*-----------------------------------------------------------------------------
*------------------MOVEM CODE STARTS HERE------------------------------------
*----------------------------------------------------------------------------


*-----------------------------------------------------------
* VERIFY_OPCODE_MOVEM
*-----------------------------------------------------------	
VERIFY_OPCODE_MOVEM     *Second verification step for movem

    MOVEM.W (A3),D2     *move memory to data register
    LSR.L   #7,D2       *shift bits to check the 9,8,7 bits match
    AND     #$07,D2
    CMP.B   #$1,D2      * verify that 001 is there after direction bit
    JMP     OPCODE_IS_MOVEM
    
OPCODE_IS_MOVEM

    LEA STR_MOVEM, A1          *Print MOVEM to console
    MOVE.B #14, D0
    TRAP #15
    JSR PRINT_DOT               *Print decimal
    JSR MOVEM_DETERMINE_SIZE   *Check if MEM TO REG OR REG TO MEM
   
     
MOVEM_DETERMINE_SIZE            *Checks for 0 or 1 at S bit
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3     
    JSR     ANALYZE_TWELVE_BITS
    MOVE    SECOND_THREE_BITS_IN_TWELVE_BITS, D3  
    CMP.B   #$2,D3
    BEQ     M0VE_SIZE_WORD
    JMP     MOVE_SIZE_LONG
    
M0VE_SIZE_WORD                  *Print W, advance to get direction

    JSR PRINT_WORD_SIZE         
    JSR PRINT_SPACE
    JSR ASSIGN_MOVEM_DIRECTION  *transition to addressing
  
MOVE_SIZE_LONG                  *Print L, advance to get direction

    JSR PRINT_LONG_SIZE         
    JSR PRINT_SPACE
    JSR ASSIGN_MOVEM_DIRECTION 
    
ASSIGN_MOVEM_DIRECTION          *All parts oK here
    CMP #$4,FIRST_THREE_BITS_IN_TWELVE_BITS
    BEQ REG_TO_MEM_MOVEM
    CMP #$6, FIRST_THREE_BITS_IN_TWELVE_BITS
    BEQ MEM_TO_REG_MOVEM
    BRA OPCODE_IS_INVALID
    
MEM_TO_REG_MOVEM
    JSR GET_NEXT_WORD                   *Advance to next word      
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3  *007F in D3 AND D7
    MOVE.W D3,D7 
    
    CMP.W #$FE00,D7
    BEQ MOVEM_M_TO_R_OUTPUT_1
    CMP.W #$00FE,D7
    BEQ MOVEM_M_TO_R_OUTPUT_2
    CMP.W #$0280,D7
    BEQ MOVEM_M_TO_R_OUTPUT_3
    
    *BRA OPCODE_IS_INVALID
     
REG_TO_MEM_MOVEM 

    JSR GET_NEXT_WORD                   *Advance to next word      
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3  *007F in D3 AND D7
    MOVE.W D3,D7 
    
    CMP.W #$007F,D7
    BEQ MOVEM_R_TO_M_OUTPUT_1
    CMP.W #$FE00,D7
    BEQ MOVEM_R_TO_M_OUTPUT_1

    
    CMP.W #$7F00,D7
    BEQ MOVEM_R_TO_M_OUTPUT_2
    CMP.W #$00FE,D7
    BEQ MOVEM_R_TO_M_OUTPUT_2
    
    CMP.W #$0140,D7
    BEQ MOVEM_R_TO_M_OUTPUT_3
    CMP.W #$0280,D7 
    BEQ MOVEM_R_TO_M_OUTPUT_3
    *BRA OPCODE_IS_INVALID
    

    BRA START_TO_HANDLE_OPCODE
   
MOVEM_R_TO_M_OUTPUT_1
    JSR PRINT_A
    JSR ONE    
    JSR PRINT_MINUS
    JSR PRINT_A
    JSR SEVEN
    JSR PRINT_COMMA
    JSR OUTPUT_SOURCE
    BRA START_TO_HANDLE_OPCODE   
MOVEM_R_TO_M_OUTPUT_2
    JSR PRINT_D
    JSR ONE
    JSR PRINT_MINUS
    JSR PRINT_D
    JSR SEVEN
    JSR PRINT_COMMA
    JSR OUTPUT_SOURCE
    BRA START_TO_HANDLE_OPCODE
MOVEM_R_TO_M_OUTPUT_3
    JSR PRINT_A
    JSR ONE
    JSR PRINT_BS
    JSR PRINT_D
    JSR SEVEN    
    JSR PRINT_COMMA
    JSR OUTPUT_SOURCE
    BRA START_TO_HANDLE_OPCODE 
    
    
MOVEM_M_TO_R_OUTPUT_1
    JSR OUTPUT_SOURCE
    JSR PRINT_COMMA
    JSR PRINT_A
    JSR ONE    
    JSR PRINT_MINUS
    JSR PRINT_A
    JSR SEVEN
    BRA START_TO_HANDLE_OPCODE   
MOVEM_M_TO_R_OUTPUT_2
        
    JSR OUTPUT_SOURCE
    JSR PRINT_COMMA
    JSR PRINT_D
    JSR ONE
    JSR PRINT_MINUS
    JSR PRINT_D
    JSR SEVEN

    BRA START_TO_HANDLE_OPCODE
MOVEM_M_TO_R_OUTPUT_3
    JSR OUTPUT_SOURCE
    JSR PRINT_COMMA    
    JSR PRINT_A
    JSR ONE
    JSR PRINT_BS
    JSR PRINT_D
    JSR SEVEN

    BRA START_TO_HANDLE_OPCODE 
            
           
PRINT_D
    LEA PRTD,A1
    BRA PRINT_MESSAGE_TO_CONSOLE
     RTS
PRINT_A
    LEA PRTA,A1
    BRA PRINT_MESSAGE_TO_CONSOLE
    RTS 

PRINT_BS        LEA BACKSLASH,A1
                BRA PRINT_MESSAGE_TO_CONSOLE
    			
*-----------------------------------------------------------------------------
*------------------MOVEM CODE ENDS HERE------------------------------------
*----------------------------------------------------------------------------
******************************************************************************
******************************************************************************


	    
*    BRA OPCODE_IS_INVALID  ****this line causeing extra DATA to print
*	RTS
	
*-----------------------------------------------------------
* OPCODE_IS_RTS_JSR 
*-----------------------------------------------------------
OPCODE_IS_RTS_JSR *Assuming we will get JSR
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3  
	LSL #8, D3
	LSR #8, D3
	CMP.B #$75, D3
	BEQ IS_RTS *If your last 2 bytes is 75 then go to IS_RTS
	
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3  
	LSL #8, D3
	LSR #8, D3
	CMP.B #$71, D3
	BEQ IS_NOP_INVALID *If your last 2 bytes is 75 then go to IS_RTS
	
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3  
    JSR SAVE_THIRD_HEX_IN_D3
    LSR #2, D3 *Isolating bits to check for 10
    CMP #%10, D3
    BEQ IS_JSR        
	BRA OPCODE_IS_INVALID
	RTS

IS_NOP_INVALID
	LEA STR_DATA, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    JSR PRINT_SPACE	
    
	LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    
    JSR HEX_TO_STRING
    JSR PRINT_SPACE
    
    BRA START_TO_HANDLE_OPCODE

	
*-----------------------------------------------------------
* OPCODE_IS_LEA 
*-----------------------------------------------------------
OPCODE_IS_LEA *LEA INSTRUCTION
	LEA STR_LEA, A1 *Because it is LEA, print out LEA to the console
	MOVE.B #14, D0
	TRAP #15
	JSR PRINT_SPACE
	
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3   *Load first four hex into D3 agian to analyze
	JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
	MOVE.W THIRD_THREE_BITS_IN_TWELVE_BITS,D3 *Trying to check for 111
	CMP.W #%111, D3 *IF 111 then print the hex
	BEQ IS_LEA_ABSOLUTE_ADDRESS *LEA $12, A0

	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3   *Load first four hex into D3 agian to analyze
    JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
    JSR OUTPUT_SOURCE                    *output source to console
    JSR PRINT_COMMA                      *print comma ','
    JSR PRINT_SPACE                      *print ' '
    JSR OUTPUT_ADDRESS_REGISTER    

	MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
    JSR PRINT_REGISTER_NUM
    BRA START_TO_HANDLE_OPCODE
    RTS

*-----------------------------------------------------------
* IS_LEA_ABSOLUTE_ADDRESS
*-----------------------------------------------------------
IS_LEA_ABSOLUTE_ADDRESS
	LEA STR_HEX, A1 *PRINTS $
	MOVE.B #14, D0
	TRAP #15
	
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Load first four hex
	JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
	MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, D3 *Analyze fourth three bits
	JSR SECONDSECTION *#%000 is word data/ #%001 is longword data

	JSR PRINT_COMMA
	JSR PRINT_SPACE                    
    JSR OUTPUT_ADDRESS_REGISTER    
	MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
    JSR PRINT_REGISTER_NUM
    BRA START_TO_HANDLE_OPCODE
	RTS
	
*-----------------------------------------------------------
* IS_JSR
* JSR < ea > 
*-----------------------------------------------------------
IS_JSR *PRINTS OUT JSR
	LEA STR_JSR, A1 *PRINTS JSR
	MOVE.B #14, D0
	TRAP #15
	JSR PRINT_SPACE

	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3   *Load first four hex into D3 agian to analyze
	JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
	MOVE.W THIRD_THREE_BITS_IN_TWELVE_BITS,D3 *Trying to check for 111
	CMP.W #%111, D3 *IF 111 then print the hex
	
	BEQ IS_JSR_ABSOLUTE_ADDRESS *To get JSR $1234, 111 is in the 3rd quarter 
	MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
	JSR OUTPUT_SOURCE *Prints JSR (A0) here
	BRA START_TO_HANDLE_OPCODE

	RTS

IS_JSR_ABSOLUTE_ADDRESS
	LEA STR_HEX, A1 *PRINTS $
	MOVE.B #14, D0
	TRAP #15

	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *Load first four hex
	JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)

	MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, D3 *Analyze fourth three bits
	JSR SECONDSECTION *#%000 is word data/ #%001 is longword data
	BRA START_TO_HANDLE_OPCODE
	BRA INVALID_INPUT
	RTS


IS_RTS *PRINTS OUT RTS
	LEA STR_RTS, A1 *Because it is JSR, print JSR to the console
	MOVE.B #14, D0
	TRAP #15
	BRA START_TO_HANDLE_OPCODE
	RTS


OPCODE_IS_BCC_BGT_BLE
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR SAVE_SECOND_HEX_IN_D3  
    CMP #%0100,D3
    BEQ OPCODE_IS_BCC
    CMP #%1110,D3
    BEQ OPCODE_IS_BGT
    CMP #%1111,D3
    BEQ OPCODE_IS_BLE

OPCODE_IS_BCC
    LEA STR_BCC,A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    JSR BCC_BGT_BLE_HELPER

OPCODE_IS_BLE
    LEA STR_BLE,A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    JSR BCC_BGT_BLE_HELPER
    
OPCODE_IS_BGT
    LEA STR_BGT,A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    JSR BCC_BGT_BLE_HELPER
   
BCC_BGT_BLE_HELPER
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR GET_EIGHT_BITS
    CMP #$00,D3
    BEQ IS_ALLZERO
    CMP #$FF,D3
    BEQ IS_ALLONE
    BRA LAST_CASE
    

GET_EIGHT_BITS
    LSL #4,D3
    LSL #4,D3
    LSR #4,D3
    LSR #4,D3 
    RTS

IS_ALLZERO
    JSR PRINT_DOT
    LEA WORD, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    JSR PRINT_SPACE
    MOVE.L A3,D4
    JSR GET_NEXT_WORD
    ADD D3,D4
    MOVE.L D4, FOUR_HEXABITS_IN_MEMORY
    JSR HEX_TO_STR_FOR_BCC
    BRA START_TO_HANDLE_OPCODE
    
IS_ALLONE
    JSR PRINT_DOT
    LEA WORD, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    
    MOVE.L A3,D4
    JSR GET_NEXT_WORD
    ADD D3,D4
    JSR GET_NEXT_WORD
    ADD D3,D4
    MOVE.L D4, FOUR_HEXABITS_IN_MEMORY
    JSR HEX_TO_STR_FOR_BCC
    BRA START_TO_HANDLE_OPCODE

LAST_CASE
    JSR PRINT_DOT
    LEA BYTE, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    JSR PRINT_SPACE
    LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    MOVE.L A3,D4
    BRA BACKWARD_OR_FORWARD
    
BACKWARD_OR_FORWARD
    CMP.W #$80,D3
    BLT IS_FORWARD
    CMP.W #$80,D3
    BGE IS_BACKWARD       
    
IS_FORWARD
    ADD D3,D4
    MOVE.L D4,FOUR_HEXABITS_IN_MEMORY
    JSR HEX_TO_STR_FOR_BCC
    BRA START_TO_HANDLE_OPCODE
    
IS_BACKWARD
    NOT.B D3
    ADDQ.W #$1,D3
    SUB D3,D4
    MOVE.L D4, FOUR_HEXABITS_IN_MEMORY
    JSR HEX_TO_STR_FOR_BCC
    BRA START_TO_HANDLE_OPCODE
   
HEX_TO_STR_FOR_BCC
    MOVE.L D4, FOUR_HEXABITS_IN_MEMORY
    JSR HEX_TO_STRING
    MOVE.W D4, FOUR_HEXABITS_IN_MEMORY
    JSR HEX_TO_STRING
    JSR PRINT_SPACE
    RTS

*When opcode is invalid (for example, ADD.W #$1234,D1 (0641 1234) this will be printed out as: 
*DATA $WXYZ where $WXYZ is the hexadecimal number that couldn't be decoded, so that the program can continue.
OPCODE_IS_INVALID 
	LEA STR_DATA, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    JSR PRINT_SPACE	
    

    LEA STR_IMM, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    JSR PRINT_SPACE	
    
    LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    
    JSR HEX_TO_STRING
    JSR PRINT_SPACE
    
    BRA START_TO_HANDLE_OPCODE
    
  
OPCODE_IS_MOVEL_OR_MOVEAL
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3   *Load first four hex into D3 agian to analyze
    JSR ANALYZE_TWELVE_BITS
    CMP #$1, SECOND_THREE_BITS_IN_TWELVE_BITS
    BEQ OPCDE_IS_MOVEAL
    BRA OPCODE_IS_MOVEL
    RTS
    
OPCDE_IS_MOVEAL
    LEA STR_MOVEA, A1 *Because it is MOVEAW, print MOVEA first to the console.
    MOVE.B #14, D0
    TRAP #15
    
    JSR PRINT_DOT
    BRA HELPER_M_L
    
HELPER_M_L
    LEA LONG, A1 *Because it is MOVEL, print L to the console.
    MOVE.B #14, D0
    TRAP #15
    JSR PRINT_SPACE 
    
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR ANALYZE_TWELVE_BITS

    JSR OUTPUT_SOURCE                    *output source to console
    JSR PRINT_COMMA                      *print comma ','
    JSR PRINT_SPACE                      *print ' '
    JSR PRINT_DESTINATION
    BRA START_TO_HANDLE_OPCODE
    RTS

OPCODE_IS_MOVEL
    LEA STR_MOVE, A1 *Because it is MOVEL, print MOVE first to the console.
    MOVE.B #14, D0
    TRAP #15
    
    JSR PRINT_DOT
    BRA HELPER_M_L

OPCODE_IS_MOVEW_OR_MOVEAW
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3   *Load first four hex into D3 agian to analyze
    JSR ANALYZE_TWELVE_BITS
    CMP #$1, SECOND_THREE_BITS_IN_TWELVE_BITS
    BEQ OPCDE_IS_MOVEAW
    BRA OPCODE_IS_MOVEW
    RTS

OPCODE_IS_MOVEW
    LEA STR_MOVE, A1 *Because it is MOVEW, print MOVE first to the console.
    MOVE.B #14, D0
    TRAP #15
    
    JSR PRINT_DOT
    BRA HELPER_M_W 

HELPER_M_W 
    LEA WORD, A1 *Because it is MOVEW, print W to the console.
    MOVE.B #14, D0
    TRAP #15
    JSR PRINT_SPACE 
    
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR ANALYZE_TWELVE_BITS

    JSR OUTPUT_SOURCE                    *output source to console
    JSR PRINT_COMMA                      *print comma ','
    JSR PRINT_SPACE                      *print ' '
    JSR PRINT_DESTINATION
    BRA START_TO_HANDLE_OPCODE
    RTS


OPCDE_IS_MOVEAW
    LEA STR_MOVEA, A1 *Because it is MOVEAW, print MOVEA first to the console.
    MOVE.B #14, D0
    TRAP #15
    
    JSR PRINT_DOT
    BRA HELPER_M_W

  
OPCODE_IS_MOVEB
    LEA STR_MOVE, A1 *Because it is MOVEB, print MOVE first to the console.
    MOVE.B #14, D0
    TRAP #15
    
    JSR PRINT_DOT
    BRA HELPER_MOVEB

HELPER_MOVEB
    LEA BYTE, A1 *Because it is MOVEB, print B to the console.
    MOVE.B #14, D0
    TRAP #15
    JSR PRINT_SPACE 
    
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR ANALYZE_TWELVE_BITS

    JSR OUTPUT_SOURCE                    *output source to console
    JSR PRINT_COMMA                      *print comma ','
    JSR PRINT_SPACE                      *print ' '
    JSR PRINT_DESTINATION
    BRA START_TO_HANDLE_OPCODE
    RTS
     

OPCODE_IS_SUB
    LEA STR_SUB, A1 *Because it is SUB, print SUB to the console.
    MOVE.B #14, D0
    TRAP #15
    JSR  PRINT_DOT
    
    BRA  HELPER_ADD_AND_OR  
    
OPCODE_IS_OR
    LEA STR_OR, A1 *Because it is OR, print OR to the console.
    MOVE.B #14, D0
    TRAP #15
    JSR  PRINT_DOT
    BRA  HELPER_ADD_AND_OR          
 

OPCODE_IS_CMP
    LEA STR_CMP, A1 *Because it is CMP, print CMP to the console.
    MOVE.B #14, D0
    TRAP #15
    
    JSR PRINT_DOT
    JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
    JSR GRAP_LAST_TWO_BITS_IN_OPMODE *in order to know the size(B/W/L) we need to grab the last two bits in opmode
    JSR PRINT_COMMON_SIZE            *print size(B/W/L)
    JSR PRINT_SPACE                   *print ' '

    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3   *Load first four hex into D3 agian to analyze
    JSR ANALYZE_TWELVE_BITS
    JSR OUTPUT_SOURCE                    *output source to console
    JSR PRINT_COMMA                      *print comma ','
    JSR PRINT_SPACE                      *print ' '
    JSR OUTPUT_DATA_REGISTER        
    
    MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
    JSR PRINT_REGISTER_NUM
    BRA START_TO_HANDLE_OPCODE
    RTS

OPCODE_IS_AND
    LEA STR_AND, A1 *Because it is AND, print AND to the console.
    MOVE.B #14, D0
    TRAP #15
    
    JSR PRINT_DOT
    BRA HELPER_ADD_AND_OR
   
      
HELPER_ADD_AND_OR *Helper for 'ADD' or 'AND' or 'OR' opcde
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
    JSR GRAP_LAST_TWO_BITS_IN_OPMODE *in order to know the size(B/W/L) we need to grab the last two bits in opmode
    JSR PRINT_COMMON_SIZE *print size(B/W/L)  
    JSR PRINT_SPACE *print ' '
    
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR ANALYZE_TWELVE_BITS
    
    CMP #0, THIRD_THREE_BITS_IN_TWELVE_BITS 
    BNE DN_IS_EITHER_SOURCE_OR_DEST 
    
    JSR OUTPUT_SOURCE   *output source to console
    JSR PRINT_COMMA     *print comma
    JSR PRINT_SPACE     *print space
    JSR OUTPUT_DATA_REGISTER
    MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
    JSR PRINT_REGISTER_NUM
    BRA START_TO_HANDLE_OPCODE *branch back to this to derive next opcode
    RTS
    
IS_NEW_SCREEN_NEEDED
    ADD      #1,D4					 
    CMP      #29,D4 																								
    BEQ      LET_USER_ENTER
    LEA      STR_SPACE,A1			
    MOVE     #14,D0					
    TRAP     #15						
    RTS		
    
LET_USER_ENTER
    LEA    STR_SPACE,A1 *print a new line
    MOVE.B #13,D0   
    TRAP   #15

    LEA STR_PRESS_ENTER, A1 *Let user press enter key to continue to next screen.
    MOVE.B #14, D0
    TRAP #15
    
    CLR      D4	
    MOVE.B   #5,D0			
    TRAP     #15			
    RTS		
    

OPCODE_IS_ADD    
    LEA STR_ADD, A1 *because it is ADD, print ADD out to console.
    MOVE.B #14,D0
    TRAP #15 *continue from here. after 00008762 ADD is printed out, it will come to this line
    
    JSR PRINT_DOT
    BRA HELPER_ADD_AND_OR


DN_IS_EITHER_SOURCE_OR_DEST
    MOVE.W FOUR_HEXABITS_IN_MEMORY,D3
    
    JSR    ANALYZE_TWELVE_BITS
    MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, D3
    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, FIRST_THREE_BITS_IN_TWELVE_BITS   
    MOVE.W D3, FOURTH_THREE_BITS_IN_TWELVE_BITS
    MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3
    MOVE.W THIRD_THREE_BITS_IN_TWELVE_BITS, SECOND_THREE_BITS_IN_TWELVE_BITS
    MOVE.W D3, THIRD_THREE_BITS_IN_TWELVE_BITS
    MOVE.W THIRD_THREE_BITS_IN_TWELVE_BITS, D3
    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
    LSR    #2,D3
    CMPI.B #%000,D3                           
    BEQ    ADD_HELPER_1	
    JSR    REGISTER_MODE_000    *it not equal to 000, then left side must be Dn            
    JSR    PRINT_COMMA			* prints a comma
    JSR    PRINT_SPACE			* prints a space
    JSR    PRINT_DESTINATION  		    
    BRA    START_TO_HANDLE_OPCODE		* branch back to DERIVING_OPCODE to see next word		
    RTS

ADD_HELPER_1 
    MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
    JSR    PRINT_DESTINATION		
    JSR    PRINT_COMMA				
    JSR    PRINT_SPACE			
    CMPI.W #%1100, D7

    BNE    ADD_HELPER_2
    CLR    D7
    MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
   	BRA ADD_HELPER_3		
    
    
ADD_HELPER_2
    CLR    D7
    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR   
    
    
ADD_HELPER_3 
    JSR    REGISTER_MODE_000			    
    BRA    START_TO_HANDLE_OPCODE	
    RTS
    
PRINT_DESTINATION
    MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR           
    MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS ,D3			  
    CMPI.B #%000,D3
    BEQ REGISTER_MODE_000
    
    CMPI.B #%001,D3
    BEQ REGISTER_MODE_001
    CMPI.B #%010,D3
    BEQ REGISTER_MODE_010
    CMPI.B #%011,D3
    BEQ REGISTER_MODE_011
    CMPI.B #%100,D3
    BEQ REGISTER_MODE_100
    CMPI.B #%111,D3
    BEQ REGISTER_MODE_111

    RTS
    

REGISTER_MODE_000                                       
    JSR OUTPUT_DATA_REGISTER		   * Print Dn
    JSR PRINT_REGISTER_NUM		   *Print register number
    RTS

REGISTER_MODE_001                                       
    JSR OUTPUT_ADDRESS_REGISTER	   * Print An
    JSR PRINT_REGISTER_NUM		   *Print register number
    RTS
    
REGISTER_MODE_010                  * Print (An)
    LEA OPENING_PARENTHESIS, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
                          
    JSR REGISTER_MODE_001		      

    LEA CLOSING_PARENTHESIS, A1
    JSR PRINT_MESSAGE_TO_CONSOLE 
    RTS
    
REGISTER_MODE_011                   * Print (An)+                      
    JSR REGISTER_MODE_010		   
    LEA PLUS, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    RTS
    
REGISTER_MODE_100                  * Print -(An)                      
    LEA MINUS, A1
    JSR PRINT_MESSAGE_TO_CONSOLE

    JSR REGISTER_MODE_010		  
    RTS
    
REGISTER_MODE_111                  *Print immediate data or absolute address 
    MOVE.W STORAGE_VAR, D3
    JSR FIRSTSECTION *NOT MOVE/MOVEA
    
    MOVE.W STORAGE_VAR, D3
    JSR SECONDSECTION
       
    RTS

FIRSTSECTION
    
    CMPI.B #$0, D3
    BEQ    OUTPUT_ONE_WORD *WORD #
    CMPI.B #$1, D3
    BEQ    OUTPUT_TWO_WORDS *LONG #
    CMPI.B #$4, D3
    BEQ    OUTPUT_IMM_DATA *IMMEDIATE #$
    
    RTS

SECONDSECTION
   
    CMPI.B #%000, D3
    BEQ    ABSOLUTE_SHORT
    CMPI.B #%001, D3
    BEQ    ABSOLUTE_LONG
    CMPI.B #%100, D3
    BEQ    IMMEDIATE_DATA


ABSOLUTE_SHORT
    JSR GET_NEXT_WORD
    JSR HEX_TO_STRING
    RTS
    SIMHALT
    
ABSOLUTE_LONG
    JSR ABSOLUTE_SHORT
    JSR ABSOLUTE_SHORT
    RTS
    SIMHALT
    *000:,11 W  001,10:L
    
IMMEDIATE_DATA
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR SAVE_FIRST_HEX_IN_D3  
    
    CMP.B #$01,D3 *MOVE/MOVEA
    BEQ   M_THIS
    CMP.B #$02,D3  *MOVE/MOVEA
    BEQ   M_THIS
    CMP.B #$03,D3   *MOVE/MOVEA
    BEQ   M_THIS

    BRA NOT_THIS    
    
M_THIS
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR SAVE_FIRST_HEX_IN_D3  
    CMP.B #$01,D3 *BYTE
    BEQ   ABSOLUTE_SHORT
    CMP.B #$02,D3  *long
    BEQ   ABSOLUTE_LONG
    CMP.B #$03,D3   *word
    BEQ   ABSOLUTE_SHORT
    
NOT_THIS
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR GRAP_LAST_TWO_BITS_IN_OPMODE *in order to know the size(B/W/L) we need to grab the last two bits in opmode
    LSR #1, D3
    JSR SECONDSECTION
    RTS
	
GRAB_MOVE_SIZE
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR SAVE_FIRST_HEX_IN_D3  
    LSL #8,D3
    LSL #8,D3
    LSL #2,D3
    LSR #8,D3
    LSR #8,D3
    LSR #2,D3
    RTS

OUTPUT_ONE_WORD
    LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    RTS
    
OUTPUT_TWO_WORDS
   LEA STR_HEX, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    RTS

OUTPUT_IMM_DATA
   LEA STR_IMM, A1
   JSR PRINT_MESSAGE_TO_CONSOLE
   LEA STR_HEX, A1
   JSR PRINT_MESSAGE_TO_CONSOLE
   
   RTS

OUTPUT_SOURCE
    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
    
    MOVE   THIRD_THREE_BITS_IN_TWELVE_BITS, D3
    
    CMPI.B #%000,D3					*Prints Dn
  	BEQ	   REGISTER_MODE_000
  	
  	CMPI.B #%001,D3			 		*Prints An
  	BEQ	   REGISTER_MODE_001

  	CMPI.B #%010,D3	                
    BEQ    REGISTER_MODE_010 
      	
    CMPI.B #%011,D3					*Prints (An)+
    BEQ    REGISTER_MODE_011 
  	
    CMPI.B #%100,D3                  *Prints -(An)
    BEQ    REGISTER_MODE_100
   
    CMPI.B #%111,D3
  	BEQ	   REGISTER_MODE_111
    
    RTS


PRINT_REGISTER_NUM 
    MOVE.W  STORAGE_VAR,D3
    CMPI.B #%000,D3					
  	BEQ		ZERO
  	CMPI.B #%001,D3
  	BEQ		ONE
  	CMPI.B #%010,D3
  	BEQ		TWO
  	CMPI.B #%011,D3
  	BEQ		THREE
  	CMPI.B #%100,D3
  	BEQ		FOUR
  	CMPI.B #%101,D3
  	BEQ		FIVE
  	CMPI.B #%110,D3
  	BEQ		SIX
  	CMPI.B #%111,D3
  	BEQ		SEVEN
  	
  	
OUTPUT_DATA_REGISTER *Dn
    LEA DATA_REGISTER, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    RTS        
    
OUTPUT_ADDRESS_REGISTER *An
    LEA ADDRESS_REGISTER, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
    RTS  

OUTPUT_OPENING_PARENTHESIS
    LEA OPENING_PARENTHESIS, A1
    JSR PRINT_MESSAGE_TO_CONSOLE
       
OUTPUT_CLOSING_PARENTHESIS
    LEA CLOSING_PARENTHESIS, A1
    JSR PRINT_MESSAGE_TO_CONSOLE

***

PRINT_COMMON_SIZE
    CMPI.B #%00,D3
  	BEQ		PRINT_BYTE_SIZE
  	CMPI.B #%01,D3
  	BEQ		PRINT_WORD_SIZE
  	CMPI.B #%10,D3
  	BEQ		PRINT_LONG_SIZE
  	CMPI.B #%00,D3
  	BEQ		PRINT_BYTE_SIZE
  	CMPI.B #%01,D3
  	BEQ		PRINT_WORD_SIZE
  	CMPI.B #%10,D3
  	BEQ		PRINT_LONG_SIZE

    RTS
    
			
    
GRAP_LAST_TWO_BITS_IN_OPMODE
    JSR ANALYZE_TWELVE_BITS
    MOVE.W SECOND_THREE_BITS_IN_TWELVE_BITS, D3
    LSL #6,D3
    LSL #8,D3
    LSR #6,D3
    LSR #8,D3
    RTS

*This analyze 12 bits in opcode and divide them into four different 3-bits so that we 
*can figure out the corresponding assembly code 
ANALYZE_TWELVE_BITS
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    LSL #4,D3
    LSR #4,D3
    LSR #4,D3
    LSR #4,D3
    LSR #1,D3
   
    MOVE.W D3, FIRST_THREE_BITS_IN_TWELVE_BITS
    
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *load the whole opcde(4-hex) back to D3 again to analyze the next 3-bits
       
    LSL #7,D3
    LSR #7,D3
    LSR #6,D3
    
    MOVE.W D3, SECOND_THREE_BITS_IN_TWELVE_BITS
    
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 *load the whole opcde(4-hex) back to D3 again to analyze the next 3-bits
    
    LSL #4,D3
    LSL #4,D3
    LSL #2,D3
    LSR #4,D3
    LSR #4,D3
    LSR #2,D3
    LSR #3,D3
    
    MOVE D3, THIRD_THREE_BITS_IN_TWELVE_BITS
    
    MOVE FOUR_HEXABITS_IN_MEMORY, D3 *load the whole opcde(4-hex) back to D3 again to analyze the next 3-bits
    LSL #4,D3
    LSL #4,D3
    LSL #5,D3
    LSR #4,D3
    LSR #4,D3
    LSR #5,D3
    
     
    MOVE.W D3,FOURTH_THREE_BITS_IN_TWELVE_BITS
    
    MOVE.W FOUR_HEXABITS_IN_MEMORY,D3
    RTS

***************
*Get next four hexabits
GET_NEXT_WORD
    MOVE.W (A3)+, D3 *A3=8762, D3 will have 0000D110.
    MOVE.W D3,FOUR_HEXABITS_IN_MEMORY
    CLR.L D7
    MOVE.W D3, D7
    CMPA.L A3,A4       *check if it reached to the ending address 
    BLE FINISH_PROGRAM
    
    RTS
    
    
PRINT_MEMORY_ADDRESS
    MOVE.L      A3,D5 
 												
    MOVE.L      D5,FOUR_HEXABITS_IN_MEMORY      
    JSR         HEX_TO_STRING			
    
    MOVE.W      A3,D5							
    MOVE.W      D5,FOUR_HEXABITS_IN_MEMORY   		
    JSR         HEX_TO_STRING		
    JSR         PRINT_SPACE			
    RTS
    SIMHALT

***
PRINT_SPACE
    LEA STR_SPACE,A1
    JSR PRINT_MESSAGE_TO_CONSOLE		
    RTS
    
PRINT_DOT
    LEA DOT,A1
    JSR PRINT_MESSAGE_TO_CONSOLE		
    RTS

    
COMPARE_NUM_OR_LETTER *to figure out if the data is 0-9 or A-F
    CMPI.B #$09,D3
    BLE NUM_CONVERSION
    BRA LETTER_CONVERSION


HEX_TO_STRING *steps to do to print as ascii
    
    MOVE.W FOUR_HEXABITS_IN_MEMORY, D3
    JSR SAVE_FIRST_HEX_IN_D3
    JSR COMPARE_NUM_OR_LETTER
        
   ****************************

    MOVE.W      FOUR_HEXABITS_IN_MEMORY,D3	 									 
    JSR        SAVE_SECOND_HEX_IN_D3 
    JSR COMPARE_NUM_OR_LETTER
    
   ******************************

    MOVE.W     FOUR_HEXABITS_IN_MEMORY,D3	 										 
    JSR         SAVE_THIRD_HEX_IN_D3
    JSR COMPARE_NUM_OR_LETTER
    
    ******************************
    
    MOVE.W      FOUR_HEXABITS_IN_MEMORY,D3										 
    JSR         SAVE_FOURTH_HEX_IN_D3  
    JSR COMPARE_NUM_OR_LETTER    
    
****
    CLR.L D3
    RTS
    
        
***********
NUM_CONVERSION
         ADDI.W #$30,D3 
         BRA CONV_LOOP

LETTER_CONVERSION
         ADDI.W #$37,D3
         BRA CONV_LOOP

CONV_LOOP  
            CMPI.B	#$30,D3
			BEQ		ZERO
			CMPI.B	#$31,D3
			BEQ		ONE
			CMPI.B	#$32,D3
			BEQ		TWO
			CMPI.B	#$33,D3
			BEQ		THREE
            CMPI.B	#$34,D3
			BEQ		FOUR
			CMPI.B	#$35,D3
			BEQ		FIVE
			CMPI.B	#$36,D3
			BEQ		SIX
			CMPI.B	#$37,D3
			BEQ		SEVEN
			CMPI.B	#$38,D3
			BEQ		EIGHT
			CMPI.B	#$39,D3
			BEQ		NINE
			
			CMPI.B	#$41,D3
			BEQ		A
			CMPI.B	#$42,D3
			BEQ		B
			CMPI.B	#$43,D3
			BEQ		C
			CMPI.B	#$44,D3
			BEQ		D
			CMPI.B	#$45,D3
			BEQ		E
			CMPI.B	#$46,D3
			BEQ		F

    
SAVE_FIRST_HEX_IN_D3 *shift to get the first hexbit
    LSR.W      #4,D3
    LSR.W      #4,D3
    LSR.W      #4,D3
    RTS
    
SAVE_SECOND_HEX_IN_D3 *shift to get the second hexbit
    LSL.L      #4,D3  
    LSR.W      #4,D3
    LSR.W      #4,D3
    LSR.W      #4,D3
    RTS
    
SAVE_THIRD_HEX_IN_D3 *shift to get the third hexbit
    LSL.L      #4,D3    
    LSL.L      #4,D3
    LSR.W      #4,D3
    LSR.W      #4,D3
    LSR.W      #4,D3    
    RTS

SAVE_FOURTH_HEX_IN_D3 *shift to get the fourth hexbit
    LSL.L       #4,D3        
    LSL.L       #4,D3    
    LSL.L       #4,D3
     LSR.W      #4,D3
    LSR.W       #4,D3
    LSR.W       #4,D3
    RTS
    
PRINT_MESSAGE_TO_CONSOLE
    MOVE.B      #14,D0
    TRAP        #15
    RTS

RESTART
    CLR.L D0
    CLR.L D1
    CLR.L D2
    CLR.L D3
    CLR.L D4
    CLR.L D5
    CLR.L D6
    CLR.L D7
    CLR.L FOUR_HEXABITS_IN_MEMORY 
    CLR.L FIRST_THREE_BITS_IN_TWELVE_BITS 
    CLR.L SECOND_THREE_BITS_IN_TWELVE_BITS 
    CLR.L THIRD_THREE_BITS_IN_TWELVE_BITS 
    CLR.L FOURTH_THREE_BITS_IN_TWELVE_BITS 
    CLR.L STORAGE_VAR
    BRA ASK_STARTING_ADDRESS
    
FINISH_PROGRAM
    LEA FINISHING_MSG, A1
    MOVE.B #13, D0
    TRAP #15
    MOVE.B #4, D0
    TRAP #15
    CMP.B #1, D1
    BEQ RESTART
    
    SIMHALT	



****
ZERO		LEA		PRT0,A1
			BRA		PRINT_NUM
ONE		    LEA		PRT1,A1
			BRA		PRINT_NUM
TWO		    LEA		PRT2,A1
			BRA		PRINT_NUM
THREE		LEA		PRT3,A1
			BRA		PRINT_NUM
FOUR		LEA		PRT4,A1
			BRA		PRINT_NUM
FIVE		LEA		PRT5,A1
			BRA		PRINT_NUM
SIX		    LEA		PRT6,A1
			BRA		PRINT_NUM
SEVEN		LEA		PRT7,A1
			BRA		PRINT_NUM
EIGHT		LEA		PRT8,A1
			BRA		PRINT_NUM
NINE		LEA		PRT9,A1
			BRA		PRINT_NUM
A		    LEA		PRTA,A1
			BRA		PRINT_NUM
B   		LEA		PRTB,A1
			BRA		PRINT_NUM
C   		LEA		PRTC,A1
			BRA		PRINT_NUM
D     		LEA		PRTD,A1
			BRA		PRINT_NUM
E		    LEA		PRTE,A1
			BRA		PRINT_NUM
F   		LEA		PRTF,A1
			BRA		PRINT_NUM
	
*****
PRINT_COMMA
    			LEA COMMA,A1
    			BRA PRINT_MESSAGE_TO_CONSOLE
    			
PRINT_PLUS      LEA PLUS,A1
                BRA PRINT_MESSAGE_TO_CONSOLE
                
PRINT_MINUS      LEA MINUS,A1
                BRA PRINT_MESSAGE_TO_CONSOLE
    			
    			
PRINT_BYTE_SIZE LEA BYTE,A1
                BRA PRINT_MESSAGE_TO_CONSOLE
PRINT_WORD_SIZE LEA WORD,A1
                BRA PRINT_MESSAGE_TO_CONSOLE
PRINT_LONG_SIZE LEA LONG,A1
                BRA PRINT_MESSAGE_TO_CONSOLE
                

*Table for 0-9 && A-F
PRT0	DC.B	'0',0
PRT1	DC.B	'1',0
PRT2	DC.B	'2',0
PRT3	DC.B	'3',0
PRT4	DC.B	'4',0
PRT5	DC.B	'5',0
PRT6	DC.B	'6',0
PRT7	DC.B	'7',0
PRT8	DC.B	'8',0
PRT9	DC.B	'9',0
PRTA	DC.B	'A',0
PRTB	DC.B	'B',0
PRTC	DC.B	'C',0
PRTD	DC.B	'D',0
PRTE	DC.B	'E',0
PRTF	DC.B	'F',0



PRINT_NUM	MOVE	#14,D0
			TRAP	#15
			RTS
    

STR_SPACE DC.W ' ',0
COMMA       DC.W ',',0	
BACKSLASH   DC.W '/', 0
STR_ADD     DC.B 'ADD',0
STR_CMP     DC.W 'CMP',0
STR_AND     DC.W 'AND',0
STR_LEA     DC.W 'LEA',0
STR_JSR     DC.W 'JSR',0
STR_SUB     DC.W 'SUB',0
STR_RTS     DC.W 'RTS',0
STR_MOVE    DC.W 'MOVE',0
STR_OR      DC.W 'OR',0
STR_LSL     DC.L 'LSL',0
STR_ASR     DC.L 'ASR',0
STR_MOVEA   DC.L 'MOVEA',0
STR_MOVEM   DC.L 'MOVEM',0
STR_BGT     DC.W 'BGT',0
STR_BLE     DC.W 'BLE',0
STR_BCC     DC.W 'BCC',0
STR_DATA	DC.W 'DATA',0


STR_HEX DC.W '$',0
STR_IMM DC.W '#',0
DOT DC.B '.',0
BYTE DC.B 'B',0
WORD DC.B 'W',0
LONG DC.B 'L',0

DATA_REGISTER DC.W 'D',0
ADDRESS_REGISTER DC.W 'A',0
OPENING_PARENTHESIS DC.W '(',0
CLOSING_PARENTHESIS DC.W ')',0
PLUS DC.W '+',0
MINUS DC.W '-',0

    
STR_PRESS_ENTER DC.W 'Please press enter key to see the next screen',0
STARTING_MESSAGE DC.W 'Please enter the starting address:',0
ENDING_MESSAGE DC.W 'Please enter the ending address(should be bigger than starting address):',0
INVALID_INPUT_MESSAGE DC.W 'You entered an invalid address, ',0
FINISHING_MSG DC.W 'To run the program again, press 1 and enter. otherwise press 0 ',0

    END $1000























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
