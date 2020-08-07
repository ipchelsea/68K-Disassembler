*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $8762
START:                 
    ADD.B 	  D0,(A0)
    ADD.L 	  D2,(A4)+
    ADD.W 	  D1, -(A5)
    ADD.W 	 (A3),D2   
    ADD.L 	 A2, D5 
    CMP.B 	 D3, D5
    CMP.W 	 A3, D5
    CMP.L   (A2), D2  
    AND.W    D0, D1
    AND.L 	(A6), D2
    AND.W    D1, (A3)
    LEA     (A0),A0
    LEA     (A5),A0
    LEA     (A7),A0
    LEA     (A0),A7
    LEA     (A5),A7
    LEA     (A7),A7
    
    
                 
    END    START        ; last line of source


























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
