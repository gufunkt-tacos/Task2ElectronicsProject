Disconnect


AudioLevel				equ	B0
AudioLevelThreshold		equ	d'1'
NtimesNoSong	equ	B1
SongDetectionFailThreshold	equ	d'2'
MicLevel				equ	B2
MicLevelThreshold			equ 	d'1'
Minutes				equ	B3
MinutesUnits			equ	B4
MinutesTens				equ	B5
Seconds				equ	B6
SecondsUnits			equ	B7
SecondsTens				equ	B8	
loopsAchieved			equ	B9
loopsTarget				equ 	d'3'



init: 
	clrf  	PORTB        ; clear PORTB output latches
	clrf		PORTA
	bsf   	STATUS,RP0   ; memory page 1
	movlw 	b'00111111'  ; set portA pins to input 
	movwf 	TRISA        ; write to TRIS register 
	movlw 	b'11000000'  ; set portB pins to output 
	movwf 	TRISB        ; write to TRIS register 
	bcf   	STATUS,RP0   ; memory page 0
	
	call		setupShiftRegisters
	goto		resetTimer

main:
	call 		recordTime
	call		formatTime
	call 		outputTime
	goto		userInputCheck
		

resetTimer:
	clrf		NtimesNoSong
	bcf		PORTA, 6
	bsf		PORTA, 7
	clrf		Minutes
	clrf		Seconds
	call		zeroOutput
	goto		waitForNewSong
	
turnOnTimer:	
	bsf		PORTA, 6
	bcf		PORTA, 7
	return

waitForNewSong:
	movlw		b'11111111'
;	readadc	B.6, AudioLevel
;    	movfw		AudioLevel
	sublw 	AudioLevelThreshold
	btfss		STATUS, C
	goto		waitForNewSong
	call		setupShiftRegisters
	call		turnOnTimer
	goto		main

waitForUnpause:
	call		loopOutputTime
	call		wait1000ms
	movlw		b'11111111'
;	readadc	B.6, AudioLevel
;    	movfw		AudioLevel
	sublw 	AudioLevelThreshold
	btfss		STATUS, C
	goto		waitForUnPause
	call		turnOnTimer
	goto		main
	

loopOutputTime:
    clrf    loopsAchieved
loopStart:
	
    call    outputTime
    incf    loopsAchieved, F

    movlw   loopsTarget
    subwf   loopsAchieved, W   ; W = loopsAchieved - loopsTarget
    btfsc   STATUS, C          ; If loopsAchieved < target, keep looping
    goto    loopStart
    nop
    return
	
userInputCheck:
	movlw		b'11111111'
;	readadc	B.7, MicLevel
;	movfw		Miclevel
	sublw 	MicLevelThreshold
	btfsc		STATUS, C
	goto		songPlayingCheck
	bcf		PORTA, 6
	clrf		NtimesNoSong
	goto		waitForUnpause

	

recordNoSong:
	incf		NtimesNoSong, 1
	movfw 	NtimesNoSong
	xorlw		SongDetectionFailThreshold
	btfsc		STATUS, Z
	goto		resetTimer
	goto		main
songPlayingCheck:
	movlw		b'11111111'
;	readadc	B.6, AudioLevel
;    	movfw		AudioLevel
	sublw 	AudioLevelThreshold
	btfss		STATUS, C
	goto		recordNoSong
	clrf		NtimesNoSong
	goto		main
	
	
pulseClock:
	bsf		PORTB, 5
	bcf		PORTB, 5
	call		wait100ms
	return
	
setupShiftRegisters:
	bsf		PORTB, 4
	
	call		pulseClock

	call		pulseClock
	call		pulseClock
	call		pulseClock
	call		pulseClock
	return
	
shiftRegisterInjection:
	bcf 		PORTB, 4
	call		pulseClock
	bsf		PORTB, 4
	return
	

incMinutes:
	incf		Minutes, 1
	movfw 	Minutes
	xorlw		d'100'
	btfsc		STATUS, Z
	clrf		Minutes	; stop minutes from going over since well we cant display it
	clrf		Seconds
	bsf		PORTA, 7	;datasheet requires 25ns so we are good with no delay
	call		wait100ms
	bcf		PORTA, 7
	return

recordTime:
	bcf		PORTA, 3
	movfw		PORTA
	andlw		b'00111111'
	movwf		Seconds
	
	movlw		d'60'
	subwf 	Seconds, W
	btfsc		STATUS, C
	return
	nop
	call		incMinutes
	return
	
	
seperateSeconds:
	movwf		SecondsUnits
	sublw		d'9'
	btfss		STATUS, C
	return
	nop
	sublw		d'255'
	movwf		SecondsUnits
	incf		SecondsTens, 1
	goto		seperateSeconds

seperateMinutes:
	movwf		MinutesUnits
	sublw		d'9'
	btfss		STATUS, C
	return
	nop
	sublw		d'255'
	movwf		MinutesUnits
	incf		MinutesTens, 1
	goto		seperateMinutes
	
	
formatTime:
	clrf    SecondsTens
	clrf    SecondsUnits
	clrf    MinutesTens
	clrf    MinutesUnits

	movfw		Seconds
	call		seperateSeconds
	movfw		Minutes
	call		seperateMinutes
	return
	
outputTime:
	call		shiftRegisterInjection

	movfw		MinutesTens
	call 		pulseClock
	movwf 	PORTB
	bsf		PORTB, 4
	
	call		wait100ms					;IMPORTANT DELAY MIGHT NEED TO CHANGE
	call		wait100ms
	
	movfw		MinutesUnits
	call		pulseClock
	movwf		PORTB
	bsf		PORTB, 4
	
	call		wait100ms					;IMPORTANT DELAY MIGHT NEED TO CHANGE
	call		wait100ms
	
	movfw		SecondsTens
	call 		pulseClock
	movwf 	PORTB
	bsf		PORTB, 4
	
	call		wait100ms					;IMPORTANT DELAY MIGHT NEED TO CHANGE
	call		wait100ms
		
	movfw		SecondsUnits
	call 		pulseClock
	movwf		PORTB
	bsf		PORTB, 4

	call		wait100ms					;IMPORTANT DELAY MIGHT NEED TO CHANGE
	call		wait100ms
	
	call		pulseClock
	return

zeroOutput:
	bcf		PORTB, 4
	call		pulseClock
	call		pulseClock
	call		pulseClock
	call		pulseClock
	call		pulseClock
	return

	
	

   