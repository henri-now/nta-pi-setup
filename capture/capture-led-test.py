#!/usr/bin/env python3
import time
import board
import neopixel

NUM = 2
PIN = board.D18 # GPIO18, physical pin 12
BRIGHTNESS = 0.2 # low; bump up only if you want it brighter

pixels = neopixel.NeoPixel(PIN, NUM, brightness=BRIGHTNESS, auto_write=False)

RED   = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE  = (0, 0, 255)
WHITE = (255, 255, 255)
OFF   = (0, 0, 0)

def both(color, hold=0.6):
    pixels.fill(color)
    pixels.show()
    time.sleep(hold)


def clear():
    pixels.fill(OFF)
    pixels.show()


try:
    print("Both pixels: RED, GREEN, BLUE, WHITE")
    for c in (RED, GREEN, BLUE, WHITE):
        both(c)

    clear()
    time.sleep(0.3)

    print("Walk each pixel individually (0 then 1)")
    for i in range(NUM):
        pixels.fill(OFF)
        pixels[i] = GREEN
        pixels.show()
        print(f"  pixel {i} should be GREEN, the other OFF")
        time.sleep(1.0)

    clear()
    time.sleep(0.3)

    print("Different color per pixel: pixel0=GREEN, pixel1=RED")
    pixels[0] = GREEN
    pixels[1] = RED
    pixels.show()
    time.sleep(2.0)

    print("Done, clearing.")
    clear()

except KeyboardInterrupt:
    clear()
