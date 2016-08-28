#ifndef FIBER_H
#define FIBER_H

#define FIBER_STACK_SIZE	128

/* Fiber Control Block (FCB) */
struct fiber {
	struct fiber *next;
	uint8_t *stackp;
	uint8_t priority;
	unsigned char stack[FIBER_STACK_SIZE];
};

/* Start a new fiber with the given priority, executing the given function. */
void spawn(struct fiber *f, int priority, void (*fn)(void *), void *arg);

/* Return the FCB of the currently executing fiber. */
struct fiber *current();

/* Schedule the given fiber for execution according to its priority. */
void wake(struct fiber *f);

/* Suspend the current fiber until awoken. */
void yield();

#endif