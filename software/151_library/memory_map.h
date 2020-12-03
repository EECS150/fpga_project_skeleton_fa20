#include "types.h"

#define COUNTER_RST (*((volatile uint32_t*) 0x80000018))
#define CYCLE_COUNTER (*((volatile uint32_t*)0x80000010))
#define INSTRUCTION_COUNTER (*((volatile uint32_t*)0x80000014))

#define GPIO_FIFO_EMPTY (*((volatile uint32_t*)0x80000020) & 0x01)
#define GPIO_FIFO_DATA (*((volatile uint32_t*)0x80000024))
#define SWITCHES (*((volatile uint32_t*)0x80000028) & 0x03)
#define LED_CONTROL (*((volatile uint32_t*)0x80000030))

#define PWM_DUTY_CYCLE (*((volatile uint32_t*)0x80000034))
#define PWM_REQ (*((volatile uint32_t*)0x80000038))
#define PWM_ACK (*((volatile uint32_t*)0x80000040))

#define HW_EN (*((volatile uint32_t*)0x80000044))
#define SINE_SHIFT (*((volatile uint32_t*)0x80000200))
#define SQUARE_SHIFT (*((volatile uint32_t*)0x80000204))
#define TRIANGLE_SHIFT (*((volatile uint32_t*)0x80000208))
#define SAWTOOTH_SHIFT (*((volatile uint32_t*)0x8000020c))
#define FCW (*((volatile uint32_t*)0x80001000))

#define GLOBAL_GAIN_SHIFT (*((volatile uint32_t*)0x80000104))
#define GLOBAL_SYNTH_RESET (*((volatile uint32_t*)0x80000100))
#define NOTE_START (*((volatile uint32_t*)0x80001004))
#define NOTE_RELEASE (*((volatile uint32_t*)0x80001008))
#define NOTE_FINISHED (*((volatile uint32_t*)0x8000100c))
#define RESET (*((volatile uint32_t*)0x80001010))

/*
#define TONE_GEN_OUTPUT_ENABLE (*((volatile uint32_t*)0x80000034))
#define TONE_GEN_TONE_INPUT (*((volatile uint32_t*)0x80000038))

#define I2S_FULL (*((volatile uint32_t*)0x80000040) & 0x01)
#define I2S_DATA (*((volatile uint32_t*)0x80000044))

// I2C Controller MMIO - reading
#define I2C_CONTROLLER_READY (*((volatile uint32_t*)0x80000100) & 0x1)
#define I2C_CONTROLLER_READ_DATA_VALID (*((volatile uint32_t*)0x80000100) & 0x2)
#define I2C_READ_DATA (*((volatile uint32_t*)0x80000104) & 0xFFFF)

// I2C Controller MMIO - writing
#define I2C_REG_ADDR (*((volatile uint32_t*)0x80000108))
#define I2C_WRITE_DATA (*((volatile uint32_t*)0x8000010C))
#define I2C_SLAVE_ADDR (*((volatile uint32_t*)0x80000110))
#define I2C_CONTROLLER_FIRE (*((volatile uint32_t*)0x80000114))
*/
