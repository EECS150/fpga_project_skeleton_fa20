#include "ascii.h"
#include "uart.h"
#include "string.h"
#include "types.h"
#include "memory_map.h"
#include "hw_scale.h"

#define BUFFER_LEN 128

void play_note(uint32_t fcw, uint32_t length) {
  FCW = fcw;
  COUNTER_RST = 0;
  NOTE_START = 1;
  while (CYCLE_COUNTER <= length) { asm volatile ("nop"); }
  NOTE_RELEASE = 1;
  while (!NOTE_FINISHED) { asm volatile ("nop"); }
  RESET = 1;
}

int main(void) {
  HW_EN = 1;

  GLOBAL_GAIN_SHIFT = 0;
  GLOBAL_SYNTH_RESET = 1;

  int8_t buffer[BUFFER_LEN];
  uint32_t note_length = (1 << 24);

  for (;;) {
    // Read the switches to determine which scale to use.
    SINE_SHIFT = (SWITCHES & 0x1) && (SWITCHES & 0x2) ? 0 : 0xFFFFFFFF;
    SQUARE_SHIFT = (SWITCHES & 0x1) && ~(SWITCHES & 0x2) ? 0 : 0xFFFFFFFF;
    TRIANGLE_SHIFT = ~(SWITCHES & 0x1) && (SWITCHES & 0x2) ? 0 : 0xFFFFFFFF;
    SAWTOOTH_SHIFT = ~(SWITCHES & 0x1) && ~(SWITCHES & 0x2) ? 0 : 0xFFFFFFFF;

    /*
    // Uncomment this to enable all scales.
    SINE_SHIFT = 0;
    SQUARE_SHIFT = 0;
    TRIANGLE_SHIFT = 0;
    SAWTOOTH_SHIFT = 0;
    */

    // Adjust the note length based on button presses
    if (!GPIO_FIFO_EMPTY) {
        uint32_t button_state = GPIO_FIFO_DATA;
        if (button_state & 0x1) {
          note_length = note_length << 1;
        }
        if (button_state & 0x2) {
          note_length = note_length >> 1;
        }
        if (button_state & 0x4) {
          note_length = (1 << 24);
        }
        uwrite_int8s("note_length = ");
        uwrite_int8s(uint32_to_ascii_hex(note_length, buffer, BUFFER_LEN));
        uwrite_int8s("\r\n");
    }

    // Begin playing a new tone if a new key is pressed
    if (URECV_CTRL) {
        uint8_t byte = URECV_DATA;
        uint32_t tone = switch_periods[byte];

        play_note(tone, note_length);
    }
  }

  return 0;
}
