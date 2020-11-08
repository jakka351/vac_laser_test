#!/bin/bash
#rpi_install.sh
#this script will install vac_laser_test to a fresh copy of raspbian lite 

##########setup
#raspi-config
#check ssh acccess
#password
#sudo passwd 

#get rid of sudo su + echo and use 'sed' command instead
sudo -Es  
#hostname
rm /boot/config.txt &&
rm /boot/cmdline.txt &&
rm /etc/motd &&
rm /etc/hostname

echo 'vaclasertest' > /etc/hostname

echo '
Dri-Sump Containment testing on GNU/Linux. 

Bluetooth Control Device.
' > /etc/motd

echo '
# For more options and information see
# http://rpf.io/configtxt
# Some settings may impact device functionality. See link above for details

#avoid_warnings=2 
#avoid_pwm_pll=1
#temp_limit=90
#1200 is 3B default, 1400 for 3B+, 1500 for 4B
[pi4]
arm_freq=1500
[pi3+]
arm_freq=1400
[pi3]
arm_freq=1200
[all]
arm_freq_min=800
#dynamic clocking
force_turbo=0
#force_turbo on boot only
initial_turbo=30
#gpu memory allocation
gpu_mem=64
#dont output to hdmi + ignorce cec commands
hdmi_ignore_hotplug=1
hdmi_ignore_cec=1
hdmi_ignore_edid_audio=1
#no boot splash 
disable_splash=1
#no need for 1.2a available at usb ports for peripherals, limits to 600ma on 3B,3B+
max_usb_current=0
#gps module uses uart
enable_uart=1
init_uart_baud=9600
#pps signal on gpio18
dtoverlay=pps-gpio,gpiopin=18
#set mac address if necessary 
#smsc95xx.macaddr=B8:AA:BC:DE:F0:12
#no audio needed
dtparam=audio=off
#hardware watchdog on/off
dtparam=watchdog=off
' > /boot/config.txt

echo '
console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait ip=192.168.0.1 smsc95xx.macaddr=B8:AA:BC:DE:F0:12
' > /boot/cmdline.txt &

#su pi 
#update & upgrade raspberry
apt update -y && apt dist-upgrade -y
apt install python python3 python-pip python3-pip -y &
apt install git curl gcc g++ make build essential -y &

#########bluetooth bluez setup
#
apt install raspi-gpio wiringpi bluez bluetooth blueman -y &
apt install ubertooth libubertooth-dev libubertooth1 bluez-firmware python-lightblue python-bluez python3-bluez -y &
apt install bluez-test-tools bluez-hcidump bluez-test-scripts bluez-test-scripts bluez-tools -y &

#sudo systemctl enable bluetooth.d
#sudo systemctl enable bluetooth.service
#sudo systemctl enable bluetooth.target
#
##############ssh over bluetooth setup######
#
#sudo su 
echo '
#!/bin/bash -e
#ssh over bluetooth 
#vaclasertest 08112020
#echo PRETTY_HOSTNAME=vaclasertest > /etc/machine-info

# edit /lib/systemd/system/bluetooth.service to enable bluetooth services
sudo sed -i: 's|^Exec.*toothd$| \
ExecStart=/usr/lib/bluetooth/bluetoothd -C \
ExecStartPost=/usr/bin/sdptool add SP \
ExecStartPost=/bin/hciconfig hci0 piscan \
|g' /lib/systemd/system/bluetooth.service

# create /etc/systemd/system/rfcomm.service to enable 
# the bluetooth serial port from systemctl
sudo cat <<EOF | sudo tee /etc/systemd/system/rfcomm.service > /dev/null
#vaclasertest 08112020
[Unit]
Description=RFCOMM service
After=bluetooth.service
Requires=bluetooth.service

[Service]
ExecStart=/usr/bin/rfcomm watch hci0 1 getty rfcomm0 115200 vt100 -a pi

[Install]
WantedBy=multi-user.target
EOF

# enable the new rfcomm service
sudo systemctl enable rfcomm

# start the rfcomm service
sudo systemctl restart rfcomm
' > /home/pi/sshbluetooth.sh 

#su pi
#
chmod 755 /home/pi/sshbluetooth.sh
#set to run at startup
echo '
#launch bluetooth service startup script ~/sshoverbluetooth.sh
./home/pi/sshoverbluetooth.sh &
' >> /etc/rc.local 
#
###########bluetooth low energy server //gatt
#this one requires nodejs
systemctl stop bluetooth &&
hciconfig &&

apt-get install -y nodejs build-essential python-dev python-rpi.gpio nodejs libudev-dev libusb-1.0-0.dev libcap2-bin &
git clone https://github.com/TheBubbleWorks/TheBubbleWorks_RaspberryPi_BLE_GPIO_Server.git /home/pi/ble &
cd /home/pi/ble &
npm install &
npm start&




############gpsd install & setup web app###########
#
apt update -y && sudo apt dist-upgrade -y &
apt install gpsd gpsd-clients python-gps python-serial python3-serial pps-tools ntp ntpstat -y &

 
#gpsd config file
echo '
#vaclasertest 08112020
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
' > /etc/default/gpsd &

#services
echo '
#vaclasertest 08112020
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

' > /lib/systemd/system/gpsd.service &

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
' > /lib/systemd/system/gpsd.socket

echo '
#vaclasertest 08112020
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
#vaclasertest 08112020
# Kernel-mode PPS ref-clock for the precise seconds
server 127.127.22.0 minpoll 4 maxpoll 4
fudge 127.127.22.0 refid PPS stratum 0

# Server from shared memory provided by gpsd
server 127.127.28.0 minpoll 4 maxpoll 4 prefer
fudge 127.127.28.0 refid NMEA stratum 3 time 1 0.000
' >> /etc/ntp.conf
##check two arrows means add to file not replace
echo '
#vaclasertest 08112020
#pps time signal 
[Time]
NTP=127.127.28.0
' >> /etc/systemd/timesyncd.conf

#back to pi user
#su pi

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
git clone ***gpslogger*** /home/pi/gpsd
sudo mkdir /home/pi/gpsd/logs
cd /home/pi/gpsd

#root
#sudo su
#python pps time script
echo '                                                                   
#vaclasertest 08112020
#pulse per second signal from ublox neo7 module pps pin = gpio 18
import os
import sys
import time
from gps import *

print 'Dri-Sump Containment Testing....locating GPS position.....'

try:
        gpsd = gps(mode=WATCH_ENABLE)
except:
        print 'No GPS connection present. TIME NOT SET.'
        sys.exit()

while True:
        gpsd.next()
        if gpsd.utc != None and gpsd.utc != '':
                gpstime = gpsd.utc[0:4] + gpsd.utc[5:7] + gpsd.utc[8:10] + ' ' + gpsd.utc[11:19]
                print 'Dri-Sump Containment Testing....setting system time to GPS time...'
                os.system('sudo date -u --set="%s"' % gpstime)
                print 'Dri-Sump Containment Testing....system time set'
                print ''                
                print 'Thanks from LOB'                
                sys.exit()
        time.sleep(1)


' > /home/pi/gpsd/pps.py

#su pi
#make executable
sudo chmod +x /home/pi/gpsd/pps.py
#set system time
sudo python /home/pi/gpsd/pps.py

#set to start on boot
echo 'sudo python /home/pi/gpsd/pps.py &' > /etc/rc.local
#show date
sudo date &&
#sudo reboot

#python gpio count
echo '
!/usr/bin/env python2.7
import os
import glob
import time
import RPi.GPIO as GPIO
from datetime import datetime
 
LED = 04
GPIO.setmode(GPIO.BCM)
GPIO.setup(LED, GPIO.OUT)
 
os.system('sudo date')
os.system('modprode pps-gpio')

base_dir = "/sys/bus/w1/devices/"
evice_folder = glob.glob(base_dir + '28*')[0]
device_file = device_folder + '/w1_slave'
 
def read_temp_raw():
 f = open(device_file, 'r')
lines = f.readlines()
  f.close()
  return lines
 def read_temp():
  lines = read_temp_raw()
 while lines[0].strip()[-3:] != 'YES':
    time.sleep(0.2)
   lines = read_temp_raw()
  equals_pos = lines[1].find('t=')
  if equals_pos != -1:
   temp_string = lines[1][equals_pos+2:]
  temp_c = float(temp_string) / 1000.0
  return temp_c
 
logdir = "/home/pi/static/"
def logToFile(filename, content):
  with open(logdir + filename, "a") as logfile:
    logfile.write(content + "\n")
#counter base 
try:
  while (True):
    for i in range(0, 29):
      time.sleep(0.5)
      if i % 2 == 0:
        GPIO.output(LED, GPIO.HIGH)
      else:
        GPIO.output(LED, GPIO.LOW)
    temperature = str(read_temp())
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    record = timestamp + ",T," + temperature
    print(record)
    logToFile("temperature.csv", record)
 
except KeyboardInterrupt:
    GPIO.output(LED, GPIO.HIGH)
    GPIO.cleanup()
GPIO.output(LED, GPIO.HIGH)
GPIO.cleanup()
' > ./countgpio.py 
##
#schematic with fritzing completed
#
#
#
#########REDUNDANCY HIDDEN WIFI AP SETUP############
#
#switch newtworking to systemd
#
#
sudo -Es   # root user
apt --autoremove purge ifupdown dhcpcd5 isc-dhcp-client isc-dhcp-common rsyslog -y 
apt-mark hold ifupdown dhcpcd5 isc-dhcp-client isc-dhcp-common rsyslog raspberrypi-net-mods openresolv
/etc/network /etc/dhcp &&

# setup/enable systemd-resolved and systemd-networkd
apt --autoremove purge avahi-daemon -y &
apt-mark hold avahi-daemon libnss-mdns -y &
apt install libnss-resolve -y &
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf &
systemctl enable systemd-networkd.service systemd-resolved.service &
exit

sudo -Es   # if not already done

cat > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf <<EOF

country=AU
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="rpi_test_AP"
    mode=2
    frequency=2437
    key_mgmt=NONE   # uncomment this for an open hotspot
    # delete next 3 lines if key_mgmt=NONE
    #key_mgmt=WPA-PSK
    #proto=RSN WPA
    #psk="00000000"
}

EOF
#

systemctl disable wpa_supplicant.service
systemctl enable wpa_supplicant@wlan0.service
rfkill unblock wlan &

#
cat > /etc/systemd/network/08-wlan0.network <<EOF

[Match]
Name=wlan0
[Network]
Address=192.168.4.1/24
MulticastDNS=yes
DHCPServer=yes

EOF	&&
sudo date

