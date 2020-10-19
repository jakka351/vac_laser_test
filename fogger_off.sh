#!/bin/bash
#fogger_off.sh
#this script sets GPIO 20 as an output and drives it low

sudo raspi-gpio set 20 op pu dl
