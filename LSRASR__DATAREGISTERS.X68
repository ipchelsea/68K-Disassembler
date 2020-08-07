*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $8762
START:                  ; first instruction of program

* Put program code here
	 LSL.B     D1,D2
     LSL.W     D1,D2
     LSL.W     (A1)
     LSL.W     (A1)+
     LSL.W     -(A1)
     LSL.L     D1,D2
     
     ASR.B     D1,D2
     ASR.W     D1,D2
     ASR.W     (A1)
     ASR.W     (A1)+
     ASR.W     -(A1)
     ASR.L     D1,D2

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
