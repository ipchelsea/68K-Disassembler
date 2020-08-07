*-----------------------------------------------------------
* Title      :
* Written by : 
* Date       :
* Description:
*-----------------------------------------------------------
STACK EQU $B000
DEST_MODE EQU 250
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
    CMP.B #$0C,D3
    BEQ OPCODE_IS_AND
    CMP.B #$4,D3
    BEQ OPCODE_IS_4
    CMP.B #$09,D3
    BEQ OPCODE_IS_SUB
    CMP.B #$00,D3
    BEQ OPCODE_IS_MOVE
    
OPCODE_IS_SUB
    LEA STR_SUB, A1 *Because it is SUB, print SUB to the console.
    MOVE.B #14, D0
    TRAP #15
    JSR  PRINT_DOT
    
    BRA  HEPLER_ADD_AND_OR  

OPCODE_IS_4
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3 
	LSL.W #8, D3
	LSR.W #8, D3
	CMPI.B #%01110101, D3 *0000 0000 0111 0101
	BNE OPCODE_IS_JSR
	BRA OPCODE_IS_RTS
	
	RTS
	
    
OPCODE_IS_LEA
	LEA STR_LEA, A1 *Because it is LEA, print out LEA to the console
	MOVE.B #14, D0
	TRAP #15
	JSR PRINT_SPACE
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3   *Load first four hex into D3 agian to analyze
    JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
    JSR OUTPUT_SOURCE                    *output source to console
    JSR PRINT_COMMA                      *print comma ','
    JSR PRINT_SPACE                      *print ' '
    JSR OUTPUT_ADDRESS_REGISTER    

	MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
    JSR PRINT_REGISTER_NUM
    BRA DERIVING_OPCODE
    RTS
	
OPCODE_IS_JSR
	LSL.W #8, D3          ;GET BIT 7 AND 6
    LSR.W #8, D3
    LSR.W #6, D3
    CMP #%10, D3 *111 010 010 000
    BEQ IS_JSR *Does the actual printing
    RTS

IS_JSR
	LEA STR_JSR, A1 *Because it is JSR, print JSR to the console
	MOVE.B #14, D0
	TRAP #15
	JSR ANALYZE_TWELVE_BITS
	MOVE.W FOUR_HEXABITS_IN_MEMORY, D3   *Load first four hex into D3 agian to analyze

	JSR PRINT_SPACE
	JSR OUTPUT_SOURCE
	
	

	BRA DERIVING_OPCODE
	RTS

OPCODE_IS_RTS
	LEA STR_RTS, A1 *Because it is JSR, print JSR to the console
	MOVE.B #14, D0
	TRAP #15
	BRA DERIVING_OPCODE
	
	RTS
 
*********************************************************** 
OPCODE_IS_MOVE
    LEA STR_MOVE,A1
    MOVE.B #14,D0
    TRAP #15
    JSR PRINT_DOT
    
    JSR ANALYZE_TWELVE_BITS *In order to print the rest, we need to analyze 12-bits in the opcde (16-bits)
    JSR GRAP_LAST_TWO_BITS_IN_OPMODE *in order to know the size(B/W/L) we need to grab the last two bits in opmode
    JSR PRINT_COMMON_SIZE            *print size(B/W/L)
    JSR PRINT_SPACE                   *print ' '
    
    MOVE.W FOUR_HEXABITS_IN_MEMORY,D6   *Load first four hex into D3 agian to analyze
    JSR ANALYZE_TWELVE_BITS
    
    JSR OUTPUT_SOURCE_MOVE                    *output source to console
    JSR PRINT_COMMA                      *print comma ','
    JSR PRINT_SPACE                      *print ' '
    JSR OUTPUT_DATA_REGISTER
    
    MOVE.W FIRST_THREE_BITS_IN_TWELVE_BITS,D3
    JSR PRINT_REGISTER_NUM
    BRA DERIVING_OPCODE
    RTS
************************************************************
    

OPCODE_IS_OR
    LEA STR_OR, A1 *Because it is OR, print OR to the console.
    MOVE.B #14, D0
    TRAP #15
    JSR  PRINT_DOT
    BRA  HEPLER_ADD_AND_OR          
 

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
    BRA HEPLER_ADD_AND_OR
   
      
HEPLER_ADD_AND_OR *Helper for 'ADD' or 'AND' or 'OR' opcde
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
    BRA HEPLER_ADD_AND_OR
    



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
    BRA START_TO_HANDLE_OPCODE		* branch back to DERIVING_OPCODE to see next word		
    RTS

ADD_HELPER_1 *Needed for DN_IS_EITHER_SOURCE_OR_DEST
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
    BRA START_TO_HANDLE_OPCODE	
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
    CMPI.B #%101,D3
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

***********************************************************
OUTPUT_SOURCE_MOVE 

    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, D6
    
    MOVE.W  THIRD_THREE_BITS_IN_TWELVE_BITS, D3
    
    CMPI.B #%000,D3					*Prints Dn
  	BEQ	   REGISTER_MODE_000
  	
  	CMPI.B #%001,D3			 		*Prints An
  	BEQ	   REGISTER_MODE_001

  	CMPI.B #%010,D3	
    BEQ    REGISTER_MODE_010 
      	
    CMPI.B #%011,D3					*Prints (An)+
    BEQ REGISTER_MODE_011 
  	
    CMPI.B #%100,D3                  *Prints -(An)
    BEQ REGISTER_MODE_100
   
    *CMPI.B #%111,D3
  	*BEQ		PRINT_IMMEDDATA_OR_ABSOADDRESS
    
    RTS    
******************************************************                              



OUTPUT_SOURCE
    MOVE.W FOURTH_THREE_BITS_IN_TWELVE_BITS, STORAGE_VAR
    
    MOVE   THIRD_THREE_BITS_IN_TWELVE_BITS, D3
    
    CMPI.B #%000,D3					*Prints Dn
  	BEQ	   REGISTER_MODE_000
  	
  	CMPI.B #%001,D3			 		*Prints An
  	BEQ	   REGISTER_MODE_001

  	CMPI.B #%010,D3					*Prints (An)
    BEQ    REGISTER_MODE_010 
      	
    CMPI.B #%011,D3					*Prints (An)+
    BEQ REGISTER_MODE_011 
  	
    CMPI.B #%100,D3                  *Prints -(An)
    BEQ REGISTER_MODE_100
   
    *CMPI.B #%111,D3
  	*BEQ		PRINT_IMMEDDATA_OR_ABSOADDRESS
    
    RTS
    
******************************************************
PRINT_REGISTER_NUM_MOVE

    MOVE.W  D6,D3
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
*************************************************


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
*******************************
PRINT_COMMON_SIZE_MOVE
    CMPI.B #%01,D3
  	BEQ		PRINT_BYTE_SIZE
  	CMPI.B #%11,D3
  	BEQ		PRINT_WORD_SIZE
  	CMPI.B #%10,D3
  	BEQ		PRINT_LONG_SIZE
  	
    RTS
*********************************

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
     		LSR.W       #4,D3
    		LSR.W       #4,D3
    		LSR.W       #4,D3
    		RTS
    
PRINT_MESSAGE_TO_CONSOLE
    		MOVE.B      #14,D0
    		TRAP        #15
    		RTS
    
FINISH_PROGRAM
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
    

STR_SPACE   DC.W ' ',0
COMMA       DC.W ',',0	
STR_ADD     DC.B 'ADD',0
STR_CMP     DC.W 'CMP',0
STR_AND     DC.W 'AND',0
STR_LEA     DC.W 'LEA',0
STR_JSR     DC.W 'JSR',0
STR_SUB     DC.W 'SUB',0
STR_RTS     DC.W 'RTS',0
STR_MOVE    DC.W 'MOVE',0
STR_OR      DC.W 'OR',0
STR_LSL     DC.W 'LSL',0
STR_ASR     DC.W 'ASR',0
STR_MOVEA   DC.L 'MOVEA',0
STR_MOVEM   DC.L 'MOVEM',0
STR_BGT     DC.W 'BGT',0
STR_BLE     DC.W 'BLE',0
STR_BCC     DC.W 'BCC',0




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
ENDING_MESSAGE DC.W 'Please enter the ending address:',0
INVALID_INPUT_MESSAGE DC.W 'You entered an invalid address, ',0


    END $1000

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
