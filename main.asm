  .mmregs
  .def _c_int00
  .text
  
;main begin
_c_int00:
 	stm #stack, SP 	;stack init 
  	ld #temp, DP	;data pointer init
  	ssbx sxm	;set extension mode
  	ssbx ovm	;set overflow correction
  	ssbx frct	;set multiplier sign bit correction (>>1)
  	nop
  	
  	;init calc_arg args
  	stm #C1,  AR2	;AR2 - const cos(a)
  	stm #S1,  AR3	;AR3 - const sin(a)
  	stm #arg, AR4	;AR4 - argument value
  	stm #m	, AR5	;AR5 - M value
  	call calc_arg
  	
  	;init calc_harm args
  	stm #C1, AR2	;AR2 - const cos(a)
  	stm #S1, AR3	;AR3 - const sin(a)
  	stm #Cn, AR4	;AR4 - current cos(a+nk) tick
  	stm #Sn, AR5	;AR5 - current sin(a+nk) tick
  	stm #gar-1, AR1	;AR1 - counter reg.; Harmonic count value
  	call calc_harm	;call
  	
  	;init calc_sig args
  	stm #sig, AR6	;AR6 - signal array pointer
  	stm #N-1, AR1	;AR1 - counter reg.; Number of tick's
  	call calc_sig	;call

	;while(true)
loop:
  	b loop	
;main end

;calc_arg func. begin
calc_arg:
	ld *AR4, 16, A
	exp a		;check zeros
  	st  T, temp	;save T
  	ld  temp, A	;load T to A
  	sub #5, A	;A -= 5
  	stl A, temp	;save A
  	neg A
  	stl A, m	;save m value
  	ld temp, T	;load A to T
  	ld *AR4, 16, A	;load arg to a
  	norm A		;norm a to threshold
  	;now sin(arg)=arg (acc. A)
  	sth  A, *AR3 ;save sin(a)
  	
  	;cos(a) first calc begin
  		squr A, A
  		sfta A, -1
  		sth  a, temp
  		ld #0x7FFF, A
  		sub temp, A
  	;end	
  	nop
  	stl  A, *AR2 ;save cos(a)
  	
  	ld m, B
  	xc 2, BGT
  		call sin_recovery
  	
  	
  	;
  	
  	;
	ret

;alg begin
sin_recovery:
	sub #1, B
	stlm B, AR1
	rsbx frct
	nop
sin_rec_loop:
		ld  *AR3, 16, B
		mpy *AR3, *AR2, A
		sfta A, 1
		sth  A, *AR3	;sin(2a)
		
		ld B, A
		squr A, B
		sfta B, 1
		sth  B, temp
		ld #0x7FFF, B
		sub temp, B
		stl B, *AR2	;cos(2a)
		
		banz sin_rec_loop, *AR1-
		ssbx frct
		nop
	ret
;alg_end
;calc_arg func. end

;calc_harm func. begin
calc_harm:
		mpy *AR3, *AR4, A	;A =  sin(a) * cos(an)
  		mac *AR2, *AR5, A	;A += cos(a) * sin(an)
  		mpy *AR2, *AR4, B	;B =  cos(a) * cos(an)
  		mas *AR3, *AR5, B	;B -= sin(a) * sin(an)
  		sth A, *AR5 	;save Sn
  		sth B, *AR4 	;save Cn
  	banz calc_harm, *AR1-	;loop
  
  	mvdd *AR5, *AR3		;save calculated sin value
  	mvdd *AR4, *AR2		;save calculated cos value
  	st #0, *AR5		;reset sin(0) value
  	st #0x7FFF, *AR4	;reset cos(0) value
  	RET 
;calc_harm func. end


;calc_sig func. begin
calc_sig:
  		mpy *AR3, *AR4, A	;A =  sin(a) * cos(an)
  		mac *AR2, *AR5, A	;A += cos(a) * sin(an)
		mpy *AR2, *AR4, B	;B =  cos(a) * cos(an)
		mas *AR3, *AR5, B	;B -= sin(a) * sin(an)
  		sth A, *AR6+		;save current sine value
  		sth A, *AR5 ;Sn
  		sth B, *AR4 ;Cn
  	banz calc_sig, *AR1-	;loop
  	RET
;calc_sig func. end  


  .align
  .data
N 	 .set  	3096	;number of sine tick's
gar 	 .set 	0x000B	;harm. number	
temp	 .word	0x0000  ;temp for thmsng
arg	 .word 	0x2C3D	;sine argument value
m	 .word	0x0000	;m-value to calculate sin(a) value
S1 	 .word  0x0000;0x0405	;sin(a) const. value
C1 	 .word  0x0000;0x7FF0	;cos(a) const. value
Sn 	 .word  0x0000	;sin(an) value
Cn       .word  0x7FFF	;cos(an) value
sig 	 .space  (N*8*2)	;signal tick's array
stack .bes  (512*8*2)		;stack region
