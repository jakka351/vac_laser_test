#!/bin/bash
#rpi_install.sh
#this script will install vac_laser_test to a fresh copy of raspbian lite 
###you need internet connectivity for this to work properly

#######initial setup######
#raspi-config
#check ssh acccess
#password
#sudo passwd 

#get rid of sudo su + echo and use 'sed' command instead
sudo su 
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
' > /boot/cmdline.txt

su pi 
#update & upgrade raspberry
sudo apt update -y && sudo apt dist-upgrade -y
sudo apt install python python3 python-pip python3-pip -y
sudo apt install git curl gcc g++ make build essential -y &&
#
########bluetooth bluez setup
#
sudo apt install raspi-gpio wiringpi bluez bluetooth blueman -y
sudo apt install ubertooth libubertooth-dev libubertooth1 bluez-firmware python-lightblue python-bluez python3-bluez -y
sudo apt install bluez-test-tools bluez-hcidump bluez-test-scripts bluez-test-scripts libbluetooth-dev libbluetooth3 bluez-tools gnome-bluetooth gir1.2-gnomebluetooth-1.0 libgnome-bluetooth13  
#
#sudo systemctl enable bluetooth.d
#sudo systemctl enable bluetooth.service
#sudo systemctl enable bluetooth.target
#
##############ssh over bluetooth setup######
#
sudo su 
echo '
#!/bin/bash -e
#ssh over bluetooth 
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
sudo chmod 755 ~/sshbluetooth.sh
#set to run at startup
echo '
#launch bluetooth service startup script ~/sshoverbluetooth.sh
sudo ~/sshoverbluetooth.sh &
' >> /etc/rc.local 
#
###########bluetooth low energy server //gatt
#this one requires nodejs
sudo systemctl stop bluetooth
sudo hciconfig

sudo apt-get install -y nodejs build-essential python-dev python-rpi.gpio nodejs libudev-dev libusb-1.0-0.dev libcap2-bin
sudo git clone https://github.com/TheBubbleWorks/TheBubbleWorks_RaspberryPi_BLE_GPIO_Server.git
cd TheBubbleWorks_RaspberryPi_BLE_GPIO_Server
npm install

npm start
#sudo raspi-gpio set 4,17,21,22,23 op pd dl &&
#
############nodejs web app###########
#
#install node       
curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash -
#install package manager
sudo apt install nodejs npm -y
#make folder for js
sudo git clone *git address* ./node &&
cd /home/pi/node &&
#install modules
sudo npm install && 
#stat webserver
sudo node app.js 8080

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


#########wifi hostspot back up mode
sudo apt install hostapd -y
sudo apt install dnsmasq -y

sudo systemctl unmask hostapd

sudo systemctl disable hostapd
sudo systemctl disable dnsmasq

sudo nano /etc/hostapd/hostapd.conf
sudo su
echo '
#2.4GHz setup wifi 80211 b,g,n
interface=wlan0
driver=nl80211
ssid=vac_backup_AP
hw_mode=g
channel=8
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=00000000
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP TKIP
rsn_pairwise=CCMP
country_code=AU
ieee80211n=1
ieee80211d=1
' > /etc/hostapd/hostapd.conf


echo '
# Defaults for hostapd initscript
#
# WARNING: The DAEMON_CONF setting has been deprecated and will be removed
#          in future package releases.
#
# See /usr/share/doc/hostapd/README.Debian for information about alternative
# methods of managing hostapd.
#
# Uncomment and set DAEMON_CONF to the absolute path of a hostapd configuration
# file and hostapd will be started during system boot. An example configuration
# file can be found at /usr/share/doc/hostapd/examples/hostapd.conf.gz
#
DAEMON_CONF="/etc/hostapd/hostapd.conf"  

# Additional daemon options to be appended to hostapd command:-
#       -d   show more debug messages (-dd for even more)
#       -K   include key data in debug messages
#       -t   include timestamps in some debug messages
#
# Note that -B (daemon mode) and -P (pidfile) options are automatically
# configured by the init.d script and must not be added to DAEMON_OPTS.
#
#DAEMON_OPTS=""

' > /etc/default/hostapd

#sudo nano /etc/dnsmasq.conf

echo '
#AutoHotspot Config
#stop DNSmasq from using resolv.conf
no-resolv
#Interface to use
interface=wlan0
bind-interfaces
dhcp-range=10.0.0.50,10.0.0.150,12h
' > /etc/dnsmasq.conf

#sudo nano /etc/network/interfaces

echo '
 # interfaces(5) file used by ifup(8) and ifdown(8) 
# Please note that this file is written to be used with dhcpcd 
# For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf' 
# Include files from /etc/network/interfaces.d: 
source-directory /etc/network/interfaces.d 
' > /etc/network/interfaces

#sudo nano /etc/dhcpcd.conf
echo '
nohook wpa_supplicant
' >> /etc/dhcpcd.conf

#sudo nano /etc/systemd/system/autohotspot.service
echo '
[Unit]
Description=Automatically generates an internet Hotspot when a valid ssid is not in range
After=multi-user.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/autohotspot
[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/autohotspot.service	

#sudo systemctl enable autohotspot.service
#sudo nano /usr/bin/autohotspot
echo '
#!/bin/bash
#version 0.961-N/HS

#You may share this script on the condition a reference to RaspberryConnect.com 
#must be included in copies or derivatives of this script. 

#A script to switch between a wifi network and a non internet routed Hotspot
#Works at startup or with a seperate timer or manually without a reboot
#Other setup required find out more at
#http://www.raspberryconnect.com

wifidev="wlan0" #device name to use. Default is wlan0.
#use the command: iw dev ,to see wifi interface name 

IFSdef=$IFS
cnt=0
#These four lines capture the wifi networks the RPi is setup to use
wpassid=$(awk '/ssid="/{ print $0 }' /etc/wpa_supplicant/wpa_supplicant.conf | awk -F'ssid=' '{ print $2 }' | sed 's/\r//g'| awk 'BEGIN{ORS=","} {print}' | sed 's/\"/''/g' | sed 's/,$//')
IFS=","
ssids=($wpassid)
IFS=$IFSdef #reset back to defaults


#Note:If you only want to check for certain SSIDs
#Remove the # in in front of ssids=('mySSID1'.... below and put a # infront of all four lines above
# separated by a space, eg ('mySSID1' 'mySSID2')
#ssids=('mySSID1' 'mySSID2' 'mySSID3')

#Enter the Routers Mac Addresses for hidden SSIDs, seperated by spaces ie 
#( '11:22:33:44:55:66' 'aa:bb:cc:dd:ee:ff' ) 
mac=()

ssidsmac=("${ssids[@]}" "${mac[@]}") #combines ssid and MAC for checking

createAdHocNetwork()
{
    echo "Creating Hotspot"
    ip link set dev "$wifidev" down
    ip a add 10.0.0.5/24 brd + dev "$wifidev"
    ip link set dev "$wifidev" up
    dhcpcd -k "$wifidev" >/dev/null 2>&1
    systemctl start dnsmasq
    systemctl start hostapd
}

KillHotspot()
{
    echo "Shutting Down Hotspot"
    ip link set dev "$wifidev" down
    systemctl stop hostapd
    systemctl stop dnsmasq
    ip addr flush dev "$wifidev"
    ip link set dev "$wifidev" up
    dhcpcd  -n "$wifidev" >/dev/null 2>&1
}

ChkWifiUp()
{
	echo "Checking WiFi connection ok"
        sleep 20 #give time for connection to be completed to router
	if ! wpa_cli -i "$wifidev" status | grep 'ip_address' >/dev/null 2>&1
        then #Failed to connect to wifi (check your wifi settings, password etc)
	       echo 'Wifi failed to connect, falling back to Hotspot.'
               wpa_cli terminate "$wifidev" >/dev/null 2>&1
	       createAdHocNetwork
	fi
}


chksys()
{
    #After some system updates hostapd gets masked using Raspbian Buster, and above. This checks and fixes  
    #the issue and also checks dnsmasq is ok so the hotspot can be generated.
    #Check Hostapd is unmasked and disabled
    if systemctl -all list-unit-files hostapd.service | grep "hostapd.service masked" >/dev/null 2>&1 ;then
	systemctl unmask hostapd.service >/dev/null 2>&1
    fi
    if systemctl -all list-unit-files hostapd.service | grep "hostapd.service enabled" >/dev/null 2>&1 ;then
	systemctl disable hostapd.service >/dev/null 2>&1
	systemctl stop hostapd >/dev/null 2>&1
    fi
    #Check dnsmasq is disabled
    if systemctl -all list-unit-files dnsmasq.service | grep "dnsmasq.service masked" >/dev/null 2>&1 ;then
	systemctl unmask dnsmasq >/dev/null 2>&1
    fi
    if systemctl -all list-unit-files dnsmasq.service | grep "dnsmasq.service enabled" >/dev/null 2>&1 ;then
	systemctl disable dnsmasq >/dev/null 2>&1
	systemctl stop dnsmasq >/dev/null 2>&1
    fi
}


FindSSID()
{
#Check to see what SSID's and MAC addresses are in range
ssidChk=('NoSSid')
i=0; j=0
until [ $i -eq 1 ] #wait for wifi if busy, usb wifi is slower.
do
        ssidreply=$((iw dev "$wifidev" scan ap-force | egrep "^BSS|SSID:") 2>&1) >/dev/null 2>&1 
        #echo "SSid's in range: " $ssidreply
	printf '%s\n' "${ssidreply[@]}"
        echo "Device Available Check try " $j
        if (($j >= 10)); then #if busy 10 times goto hotspot
                 echo "Device busy or unavailable 10 times, going to Hotspot"
                 ssidreply=""
                 i=1
	elif echo "$ssidreply" | grep "No such device (-19)" >/dev/null 2>&1; then
                echo "No Device Reported, try " $j
		NoDevice
        elif echo "$ssidreply" | grep "Network is down (-100)" >/dev/null 2>&1 ; then
                echo "Network Not available, trying again" $j
                j=$((j + 1))
                sleep 2
	elif echo "$ssidreply" | grep "Read-only file system (-30)" >/dev/null 2>&1 ; then
		echo "Temporary Read only file system, trying again"
		j=$((j + 1))
		sleep 2
	elif echo "$ssidreply" | grep "Invalid exchange (-52)" >/dev/null 2>&1 ; then
		echo "Temporary unavailable, trying again"
		j=$((j + 1))
		sleep 2
	elif echo "$ssidreply" | grep -v "resource busy (-16)"  >/dev/null 2>&1 ; then
               echo "Device Available, checking SSid Results"
		i=1
	else #see if device not busy in 2 seconds
                echo "Device unavailable checking again, try " $j
		j=$((j + 1))
		sleep 2
	fi
done

for ssid in "${ssidsmac[@]}"
do
     if (echo "$ssidreply" | grep -F -- "$ssid") >/dev/null 2>&1
     then
	      #Valid SSid found, passing to script
              echo "Valid SSID Detected, assesing Wifi status"
              ssidChk=$ssid
              return 0
      else
	      #No Network found, NoSSid issued"
              echo "No SSid found, assessing WiFi status"
              ssidChk='NoSSid'
     fi
done
}

NoDevice()
{
	#if no wifi device,ie usb wifi removed, activate wifi so when it is
	#reconnected wifi to a router will be available
	echo "No wifi device connected"
	wpa_supplicant -B -i "$wifidev" -c /etc/wpa_supplicant/wpa_supplicant.conf >/dev/null 2>&1
	exit 1
}

chksys
FindSSID

#Create Hotspot or connect to valid wifi networks
if [ "$ssidChk" != "NoSSid" ] 
then
       if systemctl status hostapd | grep "(running)" >/dev/null 2>&1
       then #hotspot running and ssid in range
              KillHotspot
              echo "Hotspot Deactivated, Bringing Wifi Up"
              wpa_supplicant -B -i "$wifidev" -c /etc/wpa_supplicant/wpa_supplicant.conf >/dev/null 2>&1
              ChkWifiUp
       elif { wpa_cli -i "$wifidev" status | grep 'ip_address'; } >/dev/null 2>&1
       then #Already connected
              echo "Wifi already connected to a network"
       else #ssid exists and no hotspot running connect to wifi network
              echo "Connecting to the WiFi Network"
              wpa_supplicant -B -i "$wifidev" -c /etc/wpa_supplicant/wpa_supplicant.conf >/dev/null 2>&1
              ChkWifiUp
       fi
else #ssid or MAC address not in range
       if systemctl status hostapd | grep "(running)" >/dev/null 2>&1
       then
              echo "Hostspot already active"
       elif { wpa_cli status | grep "$wifidev"; } >/dev/null 2>&1
       then
              echo "Cleaning wifi files and Activating Hotspot"
              wpa_cli terminate >/dev/null 2>&1
              ip addr flush "$wifidev"
              ip link set dev "$wifidev" down
              rm -r /var/run/wpa_supplicant >/dev/null 2>&1
              createAdHocNetwork
       else #"No SSID, activating Hotspot"
              createAdHocNetwork
       fi
fi
' > /usr/bin/autohotspot

#add 'off' to ssid in wpasup
#sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

#'ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
#update_config=1
#ap_scan=1
#eapol_version=1
#country=AU
#network={
#        ssid="Joff" ###add "off" to ssid
#        scan_ssid=1
#        psk="00000000"
#}
#
#
#'

#pi
su pi
sudo chmod +x /usr/bin/autohotspot
sudo systemctl enable autohotspot.service



#python gpio count
#echo '
#!/usr/bin/env python2.7
#import os
#import glob
#import time
#import RPi.GPIO as GPIO
#from datetime import datetime
 
#LED = 04
#GPIO.setmode(GPIO.BCM)
#GPIO.setup(LED, GPIO.OUT)
# 
#os.system('sudo date')
#os.system('modprode pps-gpio')
#
#base_dir = "/sys/bus/w1/devices/"
#device_folder = glob.glob(base_dir + '28*')[0]
#device_file = device_folder + '/w1_slave'
# 
#def read_temp_raw():
 # f = open(device_file, 'r')
  #lines = f.readlines()
  #f.close()
  #return lines
 
#def read_temp():
 # lines = read_temp_raw()
  #while lines[0].strip()[-3:] != 'YES':
   # time.sleep(0.2)
    #lines = read_temp_raw()
  #equals_pos = lines[1].find('t=')
  #if equals_pos != -1:
   # temp_string = lines[1][equals_pos+2:]
    #temp_c = float(temp_string) / 1000.0
    #return temp_c
 
#logdir = "/home/pi/static/"
#def logToFile(filename, content):
 # with open(logdir + filename, "a") as logfile:
  #  logfile.write(content + "\n")
#####counter base 
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
#schematic with fritzing

	
