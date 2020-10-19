#!/bin/bash
#blower_off.sh
#this script sets GPIO 19 as an output and drives it low 

sudo raspi-gpio set 19 op pu dl
