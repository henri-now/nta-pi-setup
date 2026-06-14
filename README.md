# nta-pi-setup
A Raspberry Pi acts as a transparent network bridge between a solar inverter and the home network, passively capturing all traffic for later research and analysis.

## Connection topology:<br>
Solar inverter <---> USB Ethernet Adapter <-> Raspberry Pi <---> LAN / Router

## Quick start
- Connect the solar inverter with a network cable to the USB ethernet adapter.
- Connect the network port of the capture node (Raspberry Pi) with your home network / router.
- Plug in the USB power adapter to boot the capture node.
- After the boot sequence (typically ~45 sec), the capture node's LED indicator shows one of the states explained below.

**LED indicator meanings**:
- Red: No network link detected (solar inverter off / disconnected, network cable unplugged, USB ethernet adapter not connected) or the capture service is not running / crashed. Connecting the hardware or power-cycling should fix the issue.
- Yellow: Capture node is ready to capture network traffic, but no packets were captured in the last 10 sec.
- Green: A packet was captured in the last 10 sec.

## Autodeploy
(currently only works on Linux)<br><br>
Find SD card:
```
lsblk -o PATH,SIZE,MODEL,TRAN
```
Run `deploy.sh` (first, make deploy.sh executable, choose your image target):
```
sudo chmod +x deploy.sh
sudo ./deploy.sh /dev/sdd -u user-data
```
## Services
The capture nodes runs 3 services / timers:
```
UNIT                 LOAD   ACTIVE SUB     DESCRIPTION
capture-leds.service loaded active running NeoPixel status indicator for tcpdump capture
capture.service      loaded active running tcpdump packet capture on enx3c18a0d52e65
diskclean.timer      loaded active waiting Run diskclean periodically
```
- `capture-leds.service` only runs the LED indicator. Tt continously checks three things: whether the capture service is alive, the link state of the USB NIC and the size of the folder where the pcap's are saved. If the folder has grown since the last check, a packet was captured and written to a pcap and the LED turns green.
- `capture.service` starts / restarts the tcpdump process. Tcpdump saves files with a size of 50 MB to `/var/captures`.
- `diskclean.timer` This timer triggers `diskclean.service` every 15 min to check if the size of `/var/captures` exceeds a set threshold (default 30 GB). If this is the case, the oldest files in `/var/captures` are deleted until the size of the folder is back under the threshold.

Check if services are online:
```
systemctl list-units 'capture*' 'diskclean*
```

Check timer for diskclean:
```
systemctl list-timers diskclean.timer
```

Service / timer logs:
```
journalctl -u capture.service -f
journalctl -u capture-leds.service -f
journalctl -u diskclean.service -f
```

### Packet capture
Check traffic on USB NIC (Network Interface Card):
```
sudo tcpdump -i enx3c18a0d52e65 -n -q
```

## Neopixel indicator
Follow the setup: [NeoPixel setup notes](capture/neopixel-setup.md)

Check if Neopixel LEDs are working:
```
sudo /opt/capture-led-venv/bin/python3 capture-led-test.py
```

## Note
The code and documentation in this repository were written with AI
assistance and manually reviewed and tested. The associated paper
was written without AI assistance.
