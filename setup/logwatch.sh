#!/bin/bash
sudo journalctl -u multimacd.service -u rfd.service -u hmipserver.service -u hoco-homematic.service -f

