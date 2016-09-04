#include <avr/io.h>

#if !defined(__tmp_reg__)
    #if defined(__AVR_TINY__)
        #define __tmp_reg__ r16
    #else
        #define __tmp_reg__ r0
    #endif
#endif

#if !defined(__zero_reg__)
    #if defined(__AVR_TINY__)
        #define __zero_reg__ r17
    #else
        #define __zero_reg__ r1
    #endif
#endif

.macro X_movw dst src
#if defined(__AVR_HAVE_MOVW__) && __AVR_HAVE_MOVW__
	movw	\dst, \src
#else
	.L_movw_dst = -1
	.L_movw_src = -1
	.L_movw_n = 0
	.irp reg,	r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, \
			r10,r11,r12,r13,r14,r15,r16,r17,r18,r19, \
			r20,r21,r22,r23,r24,r25,r26,r27,r28,r29, \
			r30,r31
		.ifc \reg,\dst
			.L_movw_dst = .L_movw_n
		.endif
		.ifc \reg,\src
			.L_movw_src = .L_movw_n
		.endif
		.L_movw_n = .L_movw_n + 1
	.endr
	mov	(.L_movw_dst), (.L_movw_src)
	mov	(.L_movw_dst)+1, (.L_movw_src)+1
#endif
.endm

.section .text

.globl _f_entry
.type _f_entry, @function
_f_entry:
	/* Load argument pointer (r2:r3), entry point address (r4:r5) and
	   start executing. */
	X_movw	r24, r2
	X_movw	ZL, r4
	icall

	/* NB: Fall-through to yield. */

.globl yield
.type yield, @function
yield:
	/* Fiber is yielding, so we can assume control of interrupt state. */
	sei

	/* Preserve fiber register context. We only include callee-save
	   registers as per the C calling convention. */
	.irp	regno, 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,28,29
	push	r\regno
	.endr

	/* Store the current stack pointer into the FCB. */
	lds	ZL, _f_current
	lds	ZH, _f_current+1
	in	r18, AVR_STACK_POINTER_LO_ADDR
	in	r19, AVR_STACK_POINTER_HI_ADDR
	std	Z+2, r18
	std	Z+3, r19

yield.wait:
	/* Wait for a fiber to become available in the run queue. */
	lds	ZL, _f_queue_head
	lds	ZH, _f_queue_head+1
	cp	ZL, __zero_reg__
	cpc	ZH, __zero_reg__
	breq	yield.wait

yield.switch:
	/* Remove the first control block from the run queue. */
	cli
	lds	ZL, _f_queue_head
	lds	ZH, _f_queue_head+1
	ld	r18, Z+
	ld	r19, Z+
	sts	_f_queue_head, r18
	sei
	sts	_f_queue_head+1, r19

	/* Switch to target fiber. */
	ld	r18, Z+
	ld	r19, Z
	cli
	out	AVR_STACK_POINTER_LO_ADDR, r18
	sei
	out	AVR_STACK_POINTER_HI_ADDR, r19
	sbiw	ZL, 3
	sts	_f_current, ZL
	sts	_f_current+1, ZH

	/* Restore fiber context. */
	.irp	regno, 29,28,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2
	pop	r\regno
	.endr

	/* Resume execution. */
	ret

.globl wake
.type wake, @function
wake:
	/* Preserve the status register for the interrupt flag. */
	in	__tmp_reg__, AVR_STATUS_ADDR

	/* Load priority value from target FCB. */
	X_movw	ZL, r24
	ldd	r18, Z+4

wake.start:
	/* Search for an insertion point in the run queue. First insertion
	   point candidate is the global variable _f_queue_head. */
	ldi	XL, lo8(_f_queue_head)
	ldi	XH, hi8(_f_queue_head)

wake.next:
	/* Load FCB pointer stored at the cursor. */
	cli
	ld	ZL, X+
	out	AVR_STATUS_ADDR, __tmp_reg__
	ld	ZH, X

	/* If it's a null pointer (end of list), insert here. */
	cp	ZL, __zero_reg__
	cpc	ZH, __zero_reg__
	breq	wake.insert

	/* Compare the priority of the FCB here to our priority value. If ours
	   is lower (meaning higher priority), then insert here. */
	ldd	r19, Z+4
	cp	r18, r19
	brlo	wake.insert

	/* Address of the next insertion point is the address of the 'next'
	   field of the current FCB, which coincides with the address of the
	   FCB itself. */
	X_movw	XL, ZL
	rjmp	wake.next

wake.insert:
	/* Insert our FCB before the FCB that was previously at the insertion
	   point. We're only touching our own FCB, so no need to be careful. */
	X_movw	r20, ZL
	X_movw	ZL, r24
	st	Z+, r20
	st	Z, r21

	/* Interrupts may be enabled, so we need to check that nobody stepped
	   on our toes (an interrupt waking another fiber). Disable interrupts
	   and check that the 'next' field was not changed under us. If it was,
	   restart the whole operation from the beginning. */
	cli
	ld	r23, X
	ld	r22, -X
	cp	r20, r22
	cpc	r21, r23
	brne	wake.restart

	/* Everything checks out, so insert here and restore interrupt state. */
	st	X+, r24
	out	AVR_STATUS_ADDR, __tmp_reg__
	st	X, r25

	ret

wake.restart:
	out	AVR_STATUS_ADDR, __tmp_reg__
	rjmp	wake.start
