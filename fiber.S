.section .text

.globl _fiber_entry
.type _fiber_entry, @function
_fiber_entry:
	mov r24, r2
	mov r25, r3
	mov r30, r4
	mov r31, r5
	icall
	jmp _switch

.globl yield
.type yield, @function
yield:
	lds r30, _current
	lds r31, _current+1
	st Z+, r2
	st Z+, r3
	st Z+, r4
	st Z+, r5
	st Z+, r6
	st Z+, r7
	st Z+, r8
	st Z+, r9
	st Z+, r10
	st Z+, r11
	st Z+, r12
	st Z+, r13
	st Z+, r14
	st Z+, r15
	st Z+, r16
	st Z+, r17
	st Z+, r28
	st Z+, r29
	in r18, 0x3D
	in r19, 0x3E
	st Z+, r18
	st Z, r19

_switch:
	call _schedule
	lds r30, _current
	lds r31, _current+1
	ld r2, Z+
	ld r3, Z+
	ld r4, Z+
	ld r5, Z+
	ld r6, Z+
	ld r7, Z+
	ld r8, Z+
	ld r9, Z+
	ld r10, Z+
	ld r11, Z+
	ld r12, Z+
	ld r13, Z+
	ld r14, Z+
	ld r15, Z+
	ld r16, Z+
	ld r17, Z+
	ld r28, Z+
	ld r29, Z+
	ld r18, Z+
	ld r19, Z
	in r0, 0x3F
	cli
	out 0x3D, r18
	out 0x3F, r0
	out 0x3E, r19
	ret