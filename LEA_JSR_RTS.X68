*-----------------------------------------------------------
* Title      :
* Written by : Chelsea Ip Tze Hwan
* Date       :
* Description:
*-----------------------------------------------------------
      ORG    $8752
START:     

* Put program code here
	NOP
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
	JSR		  $12
    JSR       $1234
    JSR       $12345678
    LEA       $22,A1
    LEA       $2234,A2
    LEA       $22345678,A3
    
    JSR       label1
    JSR       label2
    JSR		  label3
    NOP
    RTS
label1
    NOP
    RTS
    LEA       $12,A0
    LEA       $1234,A0
    LEA       $12345678,A0
label2
    ADDI.B    #$12,D1
    ADDI.B    #$12,(A0)
    ADDI.B    #$12,(A0)+
    ADDI.B    #$12,-(A0)
    ADDI.B    #$12,$1234
label3
	LSL.B     #$1,D2
    LSL.W     #$2,D2
    LSL.L     #$3,D2
    LSL.W     $12
    LSL.W     $1234
    LSL.W     $12345678
    ASR.B     #$1,D2
    ASR.W     #$2,D2
    ASR.L     #$3,D2
    ASR.W     $12
    ASR.W     $1234
    ASR.W     $12345678

	

    
      SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source



















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
