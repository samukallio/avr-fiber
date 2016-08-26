#include <stdint.h>
#include <avr/interrupt.h>

#include "fiber.h"

typedef uint16_t pgm_intptr_t;

struct fiber _main_fiber = { 0 };
struct fiber *volatile _current = &_main_fiber;
struct fiber *volatile _queue[FIBER_PRIORITY_COUNT] = { 0 };

void _fiber_entry();

void spawn(struct fiber *f, int priority, void (*fn)(void *), void *arg)
{
	uint8_t *sp = f->stack + FIBER_STACK_SIZE - 1;

	/* Put the entry point into the stack, so that the first 'ret'
	   actually takes us at the start of _fiber_entry. */
	*sp-- = (pgm_intptr_t) _fiber_entry & 0xFF;
	*sp-- = (pgm_intptr_t) _fiber_entry >> 8;

	/* Argument-passing registers are caller-save and hence not stored in
	   the context, so we use callee-save registers to pass arguments to
	   a special assembly entry routine which then loads them into their
	   correct argument registers. */
	*sp-- = (intptr_t) arg & 0xFF;
	*sp-- = (intptr_t) arg >> 8;
	*sp-- = (pgm_intptr_t) fn & 0xFF;
	*sp-- = (pgm_intptr_t) fn >> 8;

	/* Leave r6-r17, r28, r29 unspecified. */
	sp -= 14;

	f->stackp = sp;
	f->priority = priority;
	f->queued = 0;

	wake(f);
}

struct fiber *current()
{
	return _current;
}

void wake(struct fiber *f)
{
	struct fiber *volatile *pf;

	if (f->queued)
		return;

	f->queued = 1;
	f->next = 0;

	/* Link at the end of the queue. */
	cli();
	for (pf = &_queue[f->priority]; *pf; pf = &(*pf)->next)
		;
	*pf = f;
	sei();
}

void _schedule()
{
	while (1) {
		for (int i = 0; i < FIBER_PRIORITY_COUNT; i++) {
			struct fiber *f = _queue[i];

			if (!f)
				continue;

			cli();
			_queue[i] = f->next;
			_current = f;
			_current->queued = 0;
			sei();

			return;
		}
	}
}
