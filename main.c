#include <avr/interrupt.h>

#include "fiber.h"
#include "sleep.h"

void print(const char *s)
{
	while (*s)
		*((volatile char *)0x20) = *s++;
}

struct print_args {
	unsigned int delay;
	const char *text;
};


__attribute__((OS_task))
void print_task(void *arg)
{
	struct print_args *p = arg;

	for (int i = 0; i < 5; i++) {
		print(p->text);
		sleep(p->delay);
	}
}

int main()
{
	struct fiber f1, f2, f3;
	uint8_t stack[3][64];

	struct print_args p1 = { .delay = 200, .text = "fiber 1\n" };
	struct print_args p2 = { .delay = 400, .text = "fiber 2\n" };
	struct print_args p3 = { .delay = 800, .text = "fiber 3\n" };

	spawn(&f1, 0, stack[0], sizeof(stack[0]), print_task, &p1);
	spawn(&f2, 0, stack[1], sizeof(stack[1]), print_task, &p2);
	spawn(&f3, 0, stack[2], sizeof(stack[2]), print_task, &p3);

	while (1) {
		print("main\n");
		sleep(100);
	}
}