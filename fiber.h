#ifndef FIBER_H
#define FIBER_H

#define FIBER_STACK_SIZE	128
#define FIBER_PRIORITY_COUNT	4

struct fiber {
	uint8_t *stackp;
	unsigned char stack[FIBER_STACK_SIZE];
	struct fiber *next;
	int priority;
	int queued;
};

void spawn(struct fiber *f, int priority, void (*fn)(void *), void *arg);
struct fiber *current();
void wake(struct fiber *f);
void yield();

#endif