#ifndef FIBER_H
#define FIBER_H

#include <stddef.h>

#define FIBER_STACK_SIZE_MIN 64

/* Fiber Control Block (FCB) */
struct fiber {
	struct fiber *next;
	uint8_t *sp;
	uint8_t priority;
};

/* Start a new fiber with the given priority, executing the given function. */
int spawn(struct fiber *f, int priority, uint8_t *stack, size_t stack_size,
          void (*fn)(void *), void *arg);

/* Return the FCB of the currently executing fiber. */
struct fiber *current();

/* Schedule the given fiber for execution according to its priority. */
void wake(struct fiber *f);

/* Suspend the current fiber until awoken. */
void yield();

#endif