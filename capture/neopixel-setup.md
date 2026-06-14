# NeoPixel Status LEDs on the Capture Pi — Setup Notes

Setup record for driving WS2812 NeoPixels from the `nta-capture` Pi
(Raspberry Pi 4/3/Zero 2, **Ubuntu 24.04 Server**, arm64) over the
PWM/DMA path on **GPIO18**.

---

## 1. Fix apt (missing `noble-updates` suite)

The image shipped with only `noble` and `noble-security` configured, so the
patched `zlib1g` (from `noble-updates`) had no matching `zlib1g-dev`, and
`bzip2` was "not installable". This blocked `build-essential`.

Edit `/etc/apt/sources.list.d/ubuntu.sources` and add `noble-updates` to the
main block's `Suites:` line:

```
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports/
Suites: noble noble-updates          # <-- added noble-updates
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
```

(Leave the separate `noble-security` block as-is.)

Then refresh and confirm `noble-updates InRelease` now appears:

```bash
sudo apt update
```

## 2. Build tools (needed to compile rpi_ws281x)

`rpi_ws281x` builds a C extension, so a compiler and Python headers are
required:

```bash
sudo apt install -y build-essential python3-dev
```

## 3. Python virtual environment

The NeoPixel libraries live in a venv at `/opt/capture-led-venv`, owned by
root (the PWM/DMA path must run as root anyway):

```bash
sudo apt install -y python3-venv
sudo python3 -m venv /opt/capture-led-venv
```

## 4. Install the NeoPixel libraries

```bash
sudo /opt/capture-led-venv/bin/pip install rpi_ws281x adafruit-circuitpython-neopixel
```

### The RPi.GPIO fix

Blinka's GPIO18 backend imports `RPi.GPIO`, which is missing / broken on
Ubuntu + recent kernels. Install the modern drop-in replacement:

```bash
sudo /opt/capture-led-venv/bin/pip install rpi-lgpio
```

`rpi-lgpio` provides the `RPi.GPIO` module name but is backed by the modern
`lgpio` interface. This resolved the `ModuleNotFoundError: No module named 'RPi'`.

## 5. Disable onboard audio (frees GPIO18 PWM)

GPIO18 shares the PWM hardware with audio. Without disabling audio, the
NeoPixel call segfaults.

Ensure `/boot/firmware/config.txt` contains:

```
dtparam=audio=off
```

Then reboot:

```bash
sudo reboot
```

## 6. Wiring (Pi 3/)

| NeoPixel | Pi header        |
|----------|------------------|
| 5V / VCC | pin 2  (5V)      |
| GND      | pin 6  (GND)     |
| DIN      | pin 12 (GPIO18)  |

## 7. Run

The PWM/DMA path requires **root**, and the libraries are only in the venv, so
always invoke the venv's python with sudo:

```bash
sudo /opt/capture-led-venv/bin/python3 your-script.py
```

> Note: don't name your script `neopixel.py` — it shadows the `neopixel`
> library and breaks the import.
