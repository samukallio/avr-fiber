#include <stdint.h>
#include <avr/interrupt.h>

#include "fiber.h"

typedef uint16_t pgm_intptr_t;

struct fiber _f_main = { 0 };
struct fiber *_f_current = &_f_main;
struct fiber *_f_queue_head = 0;

void _f_entry();

int spawn(struct fiber *f, uint8_t priority, uint8_t *stack_base,
          size_t stack_size, void (*entry)(void *), void *argument)
{
	uint8_t *stack;

	if (stack_size < FIBER_STACK_SIZE_MIN)
		return -1;

	stack = stack_base + stack_size - 1;

	/* Put the entry point into the stack, so that the first 'ret'
	   actually takes us at the start of _f_entry. */
	*stack-- = (pgm_intptr_t) _f_entry & 0xFF;
	*stack-- = (pgm_intptr_t) _f_entry >> 8;

	/* Argument-passing registers are caller-save and hence not stored in
	   the context, so we use callee-save registers to pass arguments to
	   a special assembly entry routine which then loads them into their
	   correct argument registers. */
	*stack-- = (intptr_t) argument & 0xFF;
	*stack-- = (intptr_t) argument >> 8;
	*stack-- = (pgm_intptr_t) entry & 0xFF;
	*stack-- = (pgm_intptr_t) entry >> 8;

	/* Leave r6-r17, r28, r29 unspecified. */
	f->stack = stack - 14;
	f->priority = priority;

	wake(f);

	return 0;
}

struct fiber *current()
{
	return _f_current;
}
