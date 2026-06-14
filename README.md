# nta-pi-setup
Configure a Raspberry Pi running Ubuntu 24.04 LTS as an IoT-device network-traffic capture node. A Raspberry Pi acts as a transparent network bridge between a solar inverter and the home network, passively capturing all traffic for later research and analysis.

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
## Packet capture
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
