__tmp_reg__ = 0
__zero_reg__ = 1
__SREG__ = 63
__SP_H__ = 62
__SP_L__ = 61
	.file	"main"
	.text
	.p2align	1
	.type	main._start,@function
main._start:
	push	r28
	push	r29
	in	r28, 61
	in	r29, 62
	sbiw	r28, 4
	in	r0, 63
	cli
	out	62, r29
	out	63, r0
	out	61, r28
	sbi	4, 5
	ldi	r24, 32
	ldi	r18, 0
	ldi	r19, 0
	ldi	r25, 13
	ldi	r20, 3
	ldi	r21, 0
.LBB0_1:
	in	r22, 5
	eor	r22, r24
	out	5, r22
	std	Y+4, r19
	std	Y+3, r18
	std	Y+2, r19
	std	Y+1, r18
	movw	r22, r18
	movw	r30, r18
.LBB0_2:
	ldi	r26, 1
	cpi	r22, 64
	cpc	r23, r25
	cpc	r30, r20
	cpc	r31, r21
	brsh	.LBB0_4
	mov	r26, r1
.LBB0_4:
	andi	r26, 1
	cpi	r26, 0
	brne	.LBB0_1
	;APP
	nop
	;NO_APP
	ldd	r22, Y+1
	ldd	r23, Y+2
	ldd	r30, Y+3
	ldd	r31, Y+4
	subi	r22, 255
	sbci	r23, 255
	sbci	r30, 255
	sbci	r31, 255
	std	Y+4, r31
	std	Y+3, r30
	std	Y+2, r23
	std	Y+1, r22
	rjmp	.LBB0_2
.Lfunc_end0:
	.size	main._start, .Lfunc_end0-main._start

	.globl	_start
	.type	_start,@function
_start = pm(main._start)
	.section	".note.GNU-stack","",@progbits
