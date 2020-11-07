#!/bin/bash
#rpi_install.sh
#this script will install vac_laser_test to a fresh copy of raspbian lite 
#update & upgrade raspberry
sudo apt update -y && sudo apt dist-upgrade -y
#
########bluetooth bluez setup
#
sudo apt install raspi-gpio wiringpi bluez bluetooth blueman rfkill -y
sudo apt install bluez-firmware python-lightblue python-bluez python3-bluez -y
sudo apt install bluez-test-tools bluez-hcidump bluez-test-scripts bluez-test-scripts bluez-tools -y
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
echo PRETTY_HOSTNAME=vaclasertest > /etc/machine-info

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
#
su pi && sudo reboot
#
