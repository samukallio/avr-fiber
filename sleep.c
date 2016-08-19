#include <avr/interrupt.h>
#include "fiber.h"

struct timer
{
	struct fiber *fiber;
	unsigned int ticks;
};

volatile struct timer timers[8] = { 0 };

ISR(TIMER0_OVF_vect)
{
	for (int i = 0; i < 8; i++) {
		if (!timers[i].fiber)
			continue;

		if (--timers[i].ticks == 0) {
			wake(timers[i].fiber);
			timers[i].fiber = 0;
		}
	}
}

__attribute__((constructor))
static void _setup_timer0()
{
	TIMSK = (1<<TOIE0);
	TCNT0 = 0x00;
	TCCR0 = (1<<CS01) | (1<<CS00);
	sei();
}

void sleep(unsigned int ticks)
{
	for (int i = 0; i < 8; i++) {
		if (timers[i].fiber)
			continue;

		timers[i].fiber = current();
		timers[i].ticks = ticks;

		break;
	}

	yield();
}