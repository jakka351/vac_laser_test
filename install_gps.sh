#!/bin/bash
  01001100 01100101 01101001 01100111 01101000 01110100 01101111 01101110
  _          _       _     _              _____ _______      _
 | |        (_)     | |   | |            |  _  ( ) ___ \    (_)
 | |     ___ _  __ _| |__ | |_ ___  _ __ | | | |/| |_/ /_ __ _  ___ _ __
 | |    / _ \ |/ _` | '_ \| __/ _ \| '_ \| | | | | ___ \ '__| |/ _ \ '_ \
 | |___|  __/ | (_| | | | | || (_) | | | \ \_/ / | |_/ / |  | |  __/ | | |
 \_____/\___|_|\__, |_| |_|\__\___/|_| |_|\___/  \____/|_|  |_|\___|_| |_|
                __/ |
               |___/
  01001100 01100101 01101001 01100111 01101000 01110100 01101111 01101110

  Dri-Sump Containment Testing...                       ...Control Device
                                          \  //\ /  `
                                           \//~~\\__,
                                          __  ___ __
                                 |    /\ /__`|__ |__)
                                 |___/~~\.__/|___|  \
                                       ______ _____
                                        ||__ /__`|
                                        ||___.__/|


  GPS + PPS Daemon Installer...
                                                ....Debian-GNU/Linux 2020

  01001100 01100101 01101001 01100111 01101000 01110100 01101111 01101110
  Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
  permitted by applicable law.

sudo su - <<EOF
#sudo apt update -y && sudo apt dist-upgrade -y 
sudo apt install -y gpsd gpsd-clients python-gps python-serial python3-serial pps-tools ntp ntpstat -y 
echo "configuing gps services..." 
echo ""

#gpsd config file
echo '
# https://github.com/jakka351/vac_laser_test
# Dri-Sump Containment Testing 
# Leighton OBrien pty ltd
# vaclasertest 08112020 /etc/default/gpsd 

# Start the gpsd daemon automatically at boot time
START_DAEMON="true"

# Use USB hotplugging to add new USB devices automatically to the daemon
USBAUTO="false"
	
# Devices gpsd should collect to at boot time.
# They need to be read/writeable, either by user gpsd or the group dialout.
DEVICES="/dev/ttyS0 /dev/pps0"

# Other options you want to pass to gpsd
GPSD_OPTIONS="-D 5 -N -n"
' | sudo tee /etc/default/gpsd > /dev/null

#services
echo '
# https://github.com/jakka351/vac_laser_test
# Dri-Sump Containment Testing 
# Leighton OBrien pty ltd
# vaclasertest 08112020 /lib/systemd/system/gpsd.service
[Unit]
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

' | sudo tee /lib/systemd/system/gpsd.service > /dev/null

echo '
#vaclasertest 08112020
[Unit]
Description=GPS (Global Positioning System) Daemon Sockets

[Socket]
ListenStream=/var/run/gpsd.sock
ListenStream=[::1]:2947
ListenStream=127.0.0.1:2947
SocketMode=0600

[Install]
WantedBy=sockets.target
' | sudo tee /lib/systemd/system/gpsd.socket > /dev/null

echo '
# https://github.com/jakka351/vac_laser_test
# Dri-Sump Containment Testing 
# Leighton OBrien pty ltd
# vaclasertest 08112020 /lib/systemd/system/gpsdctl@.service 
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

' | sudo tee /lib/systemd/system/gpsdctl@.service > /dev/null
#
echo "configuring pulse per second signal"
#
###pps setup
echo '
# https://github.com/jakka351/vac_laser_test
# Dri-Sump Containment Testing 
# Leighton OBrien pty ltd
# vaclasertest 08112020 /etc/ntp.conf

# Kernel-mode PPS ref-clock for the precise seconds
server 127.127.22.0 minpoll 4 maxpoll 4
fudge 127.127.22.0 refid PPS stratum 0

# Server from shared memory provided by gpsd
server 127.127.28.0 minpoll 4 maxpoll 4 prefer
fudge 127.127.28.0 refid NMEA stratum 3 time 1 0.000
' | sudo tee -a /etc/ntp.conf > /dev/null
#
echo "updating system time sync"
echo '
# https://github.com/jakka351/vac_laser_test
# Dri-Sump Containment Testing 
# Leighton OBrien pty ltd
# vaclasertest 08112020 /etc/systemd/timesyncd.conf
#pps time signal 
[Time]
NTP=127.127.28.0
' | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
#
#gpsd services
#
echo "starting gpsd service & socket..."
sudo killall gpsd
echo "sudo kill all gpsd"
sudo systemctl enable gpsd.socket
sudo systemctl start gpsd.socket
echo "systemctl enable gpsd.socket"
echo "systemctl start gpsd.socket"
sudo systemctl enable gpsd.service
sudo systemctl start gpsd.service
echo "systemctl enable gpsd.service"
echo "systemctl start gpsd.service"
sudo systemctl enable gpsdctl@.service
sudo systemctl start  gpsdctl@.service 
echo "systemctl enable gpsdctl@.service"
echo "systemctl start  gpsdctl@.service "
sudo adduser gpsd pi dialout
sudo gpsd -F /var/run/gpsd.sock 
echo ""

echo "creating gpsd directory..."
#
###gps program
#git clone ***gpslogger*** /home/pi/gpsd
sudo mkdir /home/pi/gpsd 
sudo mkdir /home/pi/gpsd/logs
cd /home/pi/gpsd
#
#
echo "creating pps.py script..."
#python pps time script
echo '                                                                   
# https://github.com/jakka351/vac_laser_test
# Dri-Sump Containment Testing 
# Leighton OBrien pty ltd
# vaclasertest 08112020 /home/pi/gpsd/pps.py 

#pulse per second signal from ublox neo7 module pps pin = gpio 18
import os
import sys
import time
from gps import *

echo 'ocating GPS position.....'

try:
        gpsd = gps(mode=WATCH_ENABLE)
except:
       
       echo 'No GPS connection present. TIME NOT SET.'
        sys.exit()

while True:
        gpsd.next()
        if gpsd.utc != None and gpsd.utc != '':
                gpstime = gpsd.utc[0:4] + gpsd.utc[5:7] + gpsd.utc[8:10] + ' ' + gpsd.utc[11:19]
               
               echo '...setting system time to gps time...'
                os.system('sudo date -u --set="%s"' % gpstime)
               
               echo '....system time set'
               
               echo ''                
               
               echo 'Thanks uBlox'                
                sys.exit()
        time.sleep(1)


' | sudo tee /home/pi/gpsd/pps.py > /dev/null
#
#
#make executable
echo "making executable, setting to start on boot..."
sudo chmod +x /home/pi/gpsd/pps.py
#set system time
sudo python /home/pi/gpsd/pps.py
echo "..."
echo ". . ."
#set to start on boot
#echo 'sudo python /home/pi/gpsd/pps.py &' | sudo tee -a /etc/rc.local > /dev/null
#show date
sudo date &&
echo "system time"

EOF
