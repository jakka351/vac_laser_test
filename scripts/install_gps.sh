#!/bin/bash
#rpi_install.sh
#this script will install vac_laser_test to a fresh copy of raspbian lite 
############gpsd install & setup web app###########
#
sudo apt update -y && sudo apt dist-upgrade -y
sudo apt install gpsd gpsd-clients python-gps python-serial python3-serial pps-tools ntp ntpstat -y

sudo su 
#gpsd config file
echo '
# Default settings for the gpsd init script and the hotplug wrapper.

# Start the gpsd daemon automatically at boot time
START_DAEMON="true"

# Use USB hotplugging to add new USB devices automatically to the daemon
USBAUTO="false"
	
# Devices gpsd should collect to at boot time.
# They need to be read/writeable, either by user gpsd or the group dialout.
DEVICES="/dev/ttyS0 /dev/pps0"

# Other options you want to pass to gpsd
GPSD_OPTIONS="-D 5 -N -n"
' > /etc/default/gpsd

#services
echo '[Unit]
Description=GPS (Global Positioning System) Daemon
Requires=gpsd.socket
# Needed with chrony SOCK refclock
After=chronyd.service

[Service]
Type=forking
EnvironmentFile=-/etc/default/gpsd
ExecStart=/usr/sbin/gpsd $GPSD_OPTIONS $DEVICES

[Install]
WantedBy=multi-user.target
Also=gpsd.socket

' > /lib/systemd/system/gpsd.service

echo '

[Unit]
Description=GPS (Global Positioning System) Daemon Sockets

[Socket]
ListenStream=/var/run/gpsd.sock
ListenStream=[::1]:2947
ListenStream=127.0.0.1:2947
SocketMode=0600

[Install]
WantedBy=sockets.target
' > /lib/systemd/system/gpsd.socket

echo '
[Unit]
Description=Manage %I for GPS daemon
Requires=gpsd.socket
BindsTo=dev-%i.device
After=dev-%i.device

[Service]
Type=oneshot
Environment="GPSD_SOCKET=/var/run/gpsd.sock"
EnvironmentFile=-/etc/default/gpsd
EnvironmentFile=-/etc/sysconfig/gpsd
RemainAfterExit=yes
ExecStart=/bin/sh -c "[ \"$USBAUTO\" = true ] && /usr/sbin/gpsdctl add /dev/%I || :"
ExecStop=/bin/sh -c "[ \"$USBAUTO\" = true ] && /usr/sbin/gpsdctl remove /dev/%I || :"

' > /lib/systemd/system/gpsdctl@.service


###pps setup
echo '
# Kernel-mode PPS ref-clock for the precise seconds
server 127.127.22.0 minpoll 4 maxpoll 4
fudge 127.127.22.0 refid PPS stratum 0

# Server from shared memory provided by gpsd
server 127.127.28.0 minpoll 4 maxpoll 4 prefer
fudge 127.127.28.0 refid NMEA stratum 3 time 1 0.000
' >> /etc/ntp.conf
##check two arrows means add to file not replace
echo '
[Time]
NTP=127.127.28.0
' >> /etc/systemd/timesyncd.conf

#back to pi user
su pi

#gpsd service & socket
sudo killall gpsd

sudo systemctl enable gpsd.socket
sudo systemctl start gpsd.socket

sudo systemctl enable gpsd.service
sudo systemctl start gpsd.service

sudo systemctl enable gpsdctl@.service
sudo systemctl start  gpsdctl@.service 

sudo adduser gpsd pi dialout
sudo gpsd -F /var/run/gpsd.sock 

###gps program
sudo git clone ***gpslogger*** ./gpsd
sudo mkdir /home/pi/logs
cd /home/pi/gpsd

#root
sudo su
#python pps time script
echo '                                                                   
import os
import sys
import time
from gps import *

print 'Attempting to access GPS time...'

try:
        gpsd = gps(mode=WATCH_ENABLE)
except:
        print 'No GPS connection present. TIME NOT SET.'
        sys.exit()

while True:
        gpsd.next()
        if gpsd.utc != None and gpsd.utc != '':
                gpstime = gpsd.utc[0:4] + gpsd.utc[5:7] + gpsd.utc[8:10] + ' ' + gpsd.utc[11:19]
                print 'Setting system time to GPS time...'
                os.system('sudo date -u --set="%s"' % gpstime)
                print 'System time set.'
                sys.exit()
        time.sleep(1)


' > /home/pi/gpsd/pps.py

su pi
#make executable
sudo chmod +x /home/pi/gpsd/pps.py
#set system time
sudo python /home/pi/gpsd/pps.py
#set to start on boot
sudo su
echo 'sudo python /home/pi/gpsd/pps.py &' > /etc/rc.local
#show date
sudo date
sudo reboot
