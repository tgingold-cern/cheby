import sys
import cheby.parser
import cheby.layout
import cheby.ual
import ualserver
from time import sleep

def run(leds):
    while True:
        for i in range(8):
            leds.leds[i].led.en = 1
            sleep(0.1)
            leds.leds[i].led.en = 0

def main():
    if len(sys.argv) != 2:
        print("missing UAL access")
        sys.exit(1)

    ual = ualserver.UALRemote(sys.argv[1])
    ual.iomap_vme(4, 0x39, 0x1000, 0x700000, 1)
    leds = cheby.ual.create_ual_access(ual, 'leds.cheby')

    run(leds)

main()
