#ifndef FIBER_H
#define FIBER_H

#define FIBER_STACK_SIZE	128

struct fiber {
	struct fiber *next;
	uint8_t *stackp;
	uint8_t priority;
	unsigned char stack[FIBER_STACK_SIZE];
};

void spawn(struct fiber *f, int priority, void (*fn)(void *), void *arg);
struct fiber *current();
void wake(struct fiber *f);
void yield();

#endif