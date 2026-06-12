# nta-pi-setup
Configure a Raspberry Pi running Ubuntu 24.04 LTS as an IoT-device network-traffic capture node

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
