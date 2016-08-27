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

	/* Fiber terminated, switch to next fiber. */
	jmp _switch

.globl yield
.type yield, @function
yield:
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

	/* Read in stack pointer. */
	in r18, 0x3D
	in r19, 0x3E

	/* Store the stack pointer into current fiber control block (the one
	   we are about to leave). */
	lds r30, _current
	lds r31, _current+1
	st Z+, r18
	st Z, r19

_switch:
	/* Find the next fiber to execute. */
	call _schedule

	/* Load the stack pointer from the current fiber control block (the one
	   that was just activated). */
	lds r30, _current
	lds r31, _current+1
	ld r18, Z+
	ld r19, Z

	/* We need to replace the stack pointer, and we need to ensure no
	   interrupts occur in the middle, so we preserve the status register
	   and clear interrupts. Interrupts stay disabled for one more
	   instruction after restoring the status register, so we restore in
	   the middle to minimize the critical section. */
	in r0, 0x3F
	cli
	out 0x3D, r18
	out 0x3F, r0
	out 0x3E, r19

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

	/* Resume fiber execution. */
	ret