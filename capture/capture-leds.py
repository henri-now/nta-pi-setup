#!/usr/bin/env python3

# Two Neopixels on GPIO18 show capture health:
# green = receiving
# yellow = ready/idle
# red = problem

import os, glob, time, subprocess
import board, neopixel

CAPTURE_DIR = "/var/captures"
PCAP_GLOB = "cap-*.pcap*"
SERVICE = "capture.service"
INTERVAL = 1.0 # check interval (seconds)
GRACE = 10.0 # seconds without growth before dropping from green


def get_nic():
    # Prefer the environment (set via EnvironmentFile); else parse the file.
    nic = os.environ.get("CAPTURE_NIC")
    if nic:
        return nic
    try:
        for line in open("/etc/default/capture"):
            if line.startswith("CAPTURE_NIC="):
                return line.split("=", 1)[1].strip().strip('"')
    except OSError:
        pass
    raise SystemExit("CAPTURE_NIC not set and /etc/default/capture not readable")


NIC = get_nic()

pixels = neopixel.NeoPixel(board.D18, 2, brightness=0.15,
                           auto_write=False, pixel_order=neopixel.GRB)

GREEN  = (0, 255, 0)
YELLOW = (255, 140, 0)
RED    = (255, 0, 0)


def total_size():
    return sum(os.path.getsize(f) for f in glob.glob(os.path.join(CAPTURE_DIR, PCAP_GLOB)))


def service_running():
    return subprocess.run(["systemctl", "is-active", "--quiet", SERVICE]).returncode == 0


def link_up():
    try:
        with open(f"/sys/class/net/{NIC}/carrier") as f:
            return f.read().strip() == "1"
    except OSError:
        return False


prev = total_size()
last_growth = time.monotonic()
current = None

while True:
    now = total_size()
    if now > prev:
        last_growth = time.monotonic()
    prev = now

    if not service_running() or not link_up():
        color = RED
    elif (time.monotonic() - last_growth) < GRACE:
        color = GREEN
    else:
        color = YELLOW

    if color != current:
        pixels.fill(color)
        pixels.show()
        current = color

    time.sleep(INTERVAL)