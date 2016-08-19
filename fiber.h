#ifndef FIBER_H
#define FIBER_H

#define FIBER_CONTEXT_R2	0
#define FIBER_CONTEXT_R3	1
#define FIBER_CONTEXT_R4	2
#define FIBER_CONTEXT_R5	3
#define FIBER_CONTEXT_R6	4
#define FIBER_CONTEXT_R7	5
#define FIBER_CONTEXT_R8	6
#define FIBER_CONTEXT_R9	7
#define FIBER_CONTEXT_R10	8
#define FIBER_CONTEXT_R11	9
#define FIBER_CONTEXT_R12	10
#define FIBER_CONTEXT_R13	11
#define FIBER_CONTEXT_R14	12
#define FIBER_CONTEXT_R15	13
#define FIBER_CONTEXT_R16	14
#define FIBER_CONTEXT_R17	15
#define FIBER_CONTEXT_R28	16
#define FIBER_CONTEXT_R29	17
#define FIBER_CONTEXT_SPL	18
#define FIBER_CONTEXT_SPH	19
#define FIBER_CONTEXT_SIZE	20

#define FIBER_STACK_SIZE	96

#define FIBER_PRIORITY_COUNT	4

struct fiber {
	unsigned char context[FIBER_CONTEXT_SIZE];
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