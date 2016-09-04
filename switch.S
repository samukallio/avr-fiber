#include <avr/io.h>

.section .text

.globl _f_entry
.type _f_entry, @function
_f_entry:
	/* Load argument pointer (r2:r3), entry point address (r4:r5) and
	   start executing. */
	movw	r24, r2
	movw	r30, r4
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
	lds	r30, _f_current
	lds	r31, _f_current+1
	in	r18, AVR_STACK_POINTER_LO_ADDR
	in	r19, AVR_STACK_POINTER_HI_ADDR
	std	Z+2, r18
	std	Z+3, r19

yield.wait:
	/* Wait for a fiber to become available in the run queue. */
	lds	r30, _f_queue_head
	lds	r31, _f_queue_head+1
	cp	r30, r1
	cpc	r31, r1
	breq	yield.wait

yield.switch:
	/* Remove the first control block from the run queue. */
	cli
	lds	r30, _f_queue_head
	lds	r31, _f_queue_head+1
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
	sbiw	r30, 3
	sts	_f_current, r30
	sts	_f_current+1, r31

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
	in	r0, AVR_STATUS_ADDR

	/* Load priority value from target FCB. */
	movw	r30, r24
	ldd	r18, Z+4

wake.start:
	/* Search for an insertion point in the run queue. First insertion
	   point candidate is the global variable _f_queue_head. */
	ldi	r26, lo8(_f_queue_head)
	ldi	r27, hi8(_f_queue_head)

wake.next:
	/* Load FCB pointer stored at the cursor. */
	cli
	ld	r30, X+
	out	AVR_STATUS_ADDR, r0
	ld	r31, X

	/* If it's a null pointer (end of list), insert here. */
	cp	r30, r1
	cpc	r31, r1
	breq	wake.insert

	/* Compare the priority of the FCB here to our priority value. If ours
	   is lower (meaning higher priority), then insert here. */
	ldd	r19, Z+4
	cp	r18, r19
	brlo	wake.insert

	/* Address of the next insertion point is the address of the 'next'
	   field of the current FCB, which coincides with the address of the
	   FCB itself. */
	movw	r26, r30
	rjmp	wake.next

wake.insert:
	/* Insert our FCB before the FCB that was previously at the insertion
	   point. We're only touching our own FCB, so no need to be careful. */
	movw	r20, r30
	movw	r30, r24
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
	out	AVR_STATUS_ADDR, r0
	st	X, r25

	ret

wake.restart:
	out	AVR_STATUS_ADDR, r0
	rjmp	wake.start
