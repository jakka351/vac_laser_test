# vac_laser_test

![alt text](https://github.com/jakka351/vac_laser_test/blob/master/_updatebluetoothrasp.png?raw=true)


issue commands via bluetooth options
->ssh over bluetooth
--btserial.sh file

->ble gatt server
-->https://learn.adafruit.com/introduction-to-bluetooth-low-energy/gatt
-->https://github.com/jakka351/raspberrypi-ble-server
-->https://gist.github.com/stonehippo/d56d626927d0d4d137428341ac95b87b
-->https://www.slideshare.net/yeokm1/introduction-to-bluetooth-low-energy

->bluetooth serial port profile



edit at will
jack contact details +61434645485 bjakkaleighton@gmail.com 

Dri-Sump Containment Tightness Testing Brainstorm

                Negative Pressure Vacuum Test
                -view chamber results -> see laser dot = pass
                -----------------------> see laser line = fail
               
                
22/10/2020 - rpi to have own gps unit,  can use ublox modules same as tardis, gpsd 

22/10/2020 - Javascript/NODEJS for language?

22/10/2020 - Redundancy in case of bluetoothache

           - bt connection dies,rpi turns on wifi hotspot that tech can connect to and troubleshoot? 
           - rpi could host local web page with control signals sent over that in event of bluetooth failure 
           - remote testing with no network coverage this could also act as a mechanism to verify machine usage
           - read only file system to help avoid sd card **/boot from usb
           - manual switches/screen gui - voids the point of having the rpi at all
           
22/10/2020 - Bluetooth Serial out
           - if rpi is on same network as phone-app there is no need for bluetooth?
           
           - **PAN bluetooth profile, can this give network access to pi,send commands, is it practical**
           
           - where is the pi mounted, can ethernet/usb be considered
           
           - does the rpi need its own internet connection - connect to app via cloud
           

22/10/2020 - Web Application Details

           - Ionic Framework - lightweight front-end (static HTML, CSS and light Javascript – with no CMS) 
           
           - Offline mode 
           
           "Using AWS AppSync in conjunction with datastore, technicians and engineers will have the
ability to work offline enabling the application to work in remote areas where internet access is
limited. The data they collect will be stored locally and then once an internet connection is
established, the data will sync to the cloud. In addition, AWS SNS will send a push notification
to the user's device to signify if the data was uploaded successfully when an internet
connection is established. (Downsides: If it does not upload correctly once a connection is
established then all the work the engineer conducted offline would go unrecorded)"



~sept 2020

     retrofit rpi to 'digitise' device.
     ---control relays via GPIO receiving commands via bluetooth serial connection
     ---gps lat/long logged??
     ---usage counter & statistics 
     ---disable onboard wifi/hidden wifi hotspot for maintenance or troubleshooting?
     ---manual switches in case of technical error?

     
     

    Potential Hardware
    -raspberry pi 
    -arduino uno/leonardo
    -ublox GPS Unit 
    -usb gps module
    -4GLTE modem - usb
    -usb camera
    -raspberry pi camera (does it need to be infrared as will be inside case?)
    -relay 

    Potential Software
    -gpsd gps socket on debian
    (sudo apt install gpsd gpsd-clients python-gps)
    -raspistill/raspivid
    -python for gpio control
    -rpicam-web-interface for easy testing of cam

    stuff that jack has available currently to play with
    -2x rpi4, 1x rpi3b, 1x rpi3a+
    -1x arduino uno, 1x arduino leonardo
    -1x Ublox7 gps unit, with both serial and usb connection
    -1x 4 channel relay 5v
    -1x picamera
    -breadboard + gpio breakout
    -1x usb wifi dongle, 2x bluetooth usb
    -various sensors and bits

    tooling
    -soldering equipment
