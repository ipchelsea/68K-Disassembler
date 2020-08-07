*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
      ORG    $8752
START:     

* Put program code here
	
	RTS
    LEA       (A0),A0
    LEA       (A5),A0
    LEA       (A7),A0
    LEA       (A0),A7
    LEA       (A5),A7
    LEA       (A7),A7
	LEA       $12,A0
    LEA       $1234,A0
    LEA       $12345678,A0
	RTS
	JSR       (A0)
	JSR       (A1)
	JSR       (A2)
    JSR       $1234
    JSR       $12345678
	
	
    
      SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source

















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
