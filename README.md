# nta-pi-setup
Configure a Raspberry Pi running Ubuntu 24.04 LTS as an IoT-device network-traffic capture node<br>
Connection topology:<br>
Solar inverter <---> USB Ethernet Adapter <-> Raspberry Pi <---> LAN / Router

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
Portions of this repo were written with AI assistance and reviewed by me.
