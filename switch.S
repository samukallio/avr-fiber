#define SPL 0x3D
#define SPH 0x3E
#define SREG 0x3F

.section .text

.globl _fiber_entry
.type _fiber_entry, @function
_fiber_entry:
	/* Load argument to entry function. */
	mov r24, r2
	mov r25, r3

	/* Load entry function address. */
	mov r30, r4
	mov r31, r5

	/* Execute fiber function. */
	icall

	/* NB: Fall-through to yield. */

.globl yield
.type yield, @function
yield:
	/* Fiber is yielding, so we can assume control of the interrupt flag. */
	sei

	/* Preserve fiber register context. We only include callee-save
	   registers as per the C calling convention. */
	push r2
	push r3
	push r4
	push r5
	push r6
	push r7
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	push r16
	push r17
	push r28
	push r29

	/* Load the address of the current FCB into X. */
	lds r26, _current
	lds r27, _current+1

	/* Load the address of the next FCB into Y and make it current.
	   The other end of this list manipulation happens in interrupts,
	   so disable them while we touch the list. */
	cli
	ld r28, X+
	ld r29, X+
	sts _current, r28
	sei
	sts _current+1, r29

	/* Store the current stack pointer into the old FCB. */
	in r2, SPL
	in r3, SPH
	st X+, r2
	st X, r3

	/* There may have been nothing else waiting to run, in that case we
	   need to wait for an interrupt to give us something to do. */
yield.wait:
	cp r28, r1
	cpc r29, r1
	brne yield.switch
	cli
	lds r28, _current
	sei
	lds r29, _current+1
	rjmp yield.wait

yield.switch:
	/* Switch to the new fiber stack. */
	ldd r2, Y+2
	ldd r3, Y+3
	cli
	out SPL, r2
	sei
	out SPH, r3

	/* Restore fiber context. */
	pop r29
	pop r28
	pop r17
	pop r16
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop r7
	pop r6
	pop r5
	pop r4
	pop r3
	pop r2

	/* Resume execution. */
	ret

.globl wake
.type wake, @function
wake:
	/* Preserve the status register for the interrupt flag. */
	in r0, SREG

	/* Load priority value from target FCB. */
	movw r30, r24
	ldd r18, Z+4

wake.start:
	/* Search for an insertion point in the run queue. First insertion
	   point candidate is the global variable _current. */
	ldi r26, lo8(_current)
	ldi r27, hi8(_current)

wake.next:
	/* Load FCB pointer stored at the cursor. */
	cli
	ld r30, X+
	out SREG, r0
	ld r31, X

	/* If it's a null pointer (end of list), insert here. */
	cp r30, r1
	cpc r31, r1
	breq wake.insert

	/* Compare the priority of the FCB here to our priority value. If ours
	   is lower (meaning higher priority), then insert here. */
	ldd r19, Z+4
	cp r18, r19
	brlo wake.insert

	/* Address of the next insertion point is the address of the 'next'
	   field of the current FCB, which coincides with the address of the
	   FCB itself. */
	movw r26, r30
	rjmp wake.next

wake.insert:
	/* Insert our FCB before the FCB that was previously at the insertion
	   point. We're only touching our own FCB, so no need to be careful. */
	movw r20, r30
	movw r30, r24
	st Z+, r20
	st Z, r21

	/* Interrupts may be enabled, so we need to check that nobody stepped
	   on our toes (an interrupt waking another fiber). Disable interrupts
	   and check that the 'next' field was not changed under us. If it was,
	   restart the whole operation from the beginning. */
	cli
	ld r23, X
	ld r22, -X
	cp r20, r22
	cpc r21, r23
	brne wake.restart

	/* Everything checks out, so insert here and restore interrupt state. */
	st X+, r24
	out SREG, r0
	st X, r25

	ret

wake.restart:
	out SREG, r0
	rjmp wake.start
