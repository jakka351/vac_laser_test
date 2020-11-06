# vac_laser_test

![alt text](https://github.com/jakka351/vac_laser_test/blob/master/_updatebluetoothrasp.png?raw=true)


**issue commands via bluetooth options**


**ssh over bluetooth**

    To be tested 7/11/2020
  
    sshoverbluetooth.sh script
  
    issue commands to pi via shell script, eg 'raspi-gpio set 4 op dh'

    serial port profile is used


**bluetooth low energy server**

    https://github.com/jakka351/boxee gpio control over ble example

>Creates a Bluetooth LE advertisement and publishes one service,which enables to set GPIO 17 and 18 to HIGH and LOW on a Raspberry PI, by writing a 2 byte value array:

    0x00 0x00 => PIN 17 and 18 is LOW
    0x00 0xFF => PIN 17 is LOW, PIN 18 is HIGH
    0xFF 0xFF => PIN 17 and 18 are HIGH

>Boxee is a Bluetooth Low Energy automation protoype for the Raspberyy PI. It relies on Dbus and Bluez to expose GPIO control over the BLE, so that one can >control GPIOs over the phone. The testing application on IOS is LightBlue

           https://github.com/thingsplode/blexee example of a phone application for IOS based on cordova
           https://learn.adafruit.com/introduction-to-bluetooth-low-energy/gatt ble intro
           https://github.com/jakka351/raspberrypi-ble-server another example
           https://gist.github.com/stonehippo/d56d626927d0d4d137428341ac95b87b another example
           https://www.slideshare.net/yeokm1/introduction-to-bluetooth-low-energy background info

edit me
jack contact details +61434645485 bjakkaleighton@gmail.com 

**Dri-Sump Containment Tightness Testing Brainstorm**

                Negative Pressure Vacuum Test
                -view chamber results -> see laser dot = pass
                -----------------------> see laser line = fail
               
                
**22/10/2020 - rpi to have own gps unit,  can use ublox modules same as tardis, gpsd **

**22/10/2020 - Javascript/NODEJS for language?**

**22/10/2020 - Redundancy in case of bluetoothache**
   
   bt connection dies,rpi turns on wifi hotspot that tech can connect to and troubleshoot? 
   
   rpi could host local web page with control signals sent over that in event of bluetooth failure      
   
   remote testing with no network coverage this could also act as a mechanism to verify machine usage           
   
   **read only file system to help avoid sd card **           

**~~22/10/2020 - Bluetooth Serial out**


**Phone App Details**

Ionic Framework - lightweight front-end (static HTML, CSS and light Javascript – with no CMS) 

Offline mode 
           
            Using AWS AppSync in conjunction with datastore, technicians and engineers will have the
            ability to work offline enabling the application to work in remote areas where internet access is
            limited. The data they collect will be stored locally and then once an internet connection is
            established, the data will sync to the cloud. In addition, AWS SNS will send a push notification
            to the user's device to signify if the data was uploaded successfully when an internet
            connection is established. (Downsides: If it does not upload correctly once a connection is
            established then all the work the engineer conducted offline would go unrecorded)"



**sept 2020**

     retrofit rpi to 'digitise' device.
    
     control relays via GPIO receiving commands via bluetooth serial connection
     
     gps lat/long logged??
     
     usage counter & statistics 
     
     disable onboard wifi/hidden wifi hotspot for maintenance or troubleshooting?
     
     manual switches in case of technical error?


**Potential Hardware**

*raspberry pi 

-arduino uno/leonardo

-ublox GPS Unit 

-usb gps module

-4GLTE modem - usb

-usb camera

-raspberry pi camera (does it need to be infrared as will be inside case?)

-relay
    
**Potential Software**

+gpsd gps socket on debian
    
    -raspistill/raspivid

    -python for gpio control

    -rpicam-web-interface for easy testing of cam 
    

**stuff that jack has available currently to play with**
    *
    
     -2x rpi4, 1x rpi3b, 1x rpi3a+  
    
     -1x arduino uno, 1x arduino leonardo
     
     -1x Ublox7 gps unit, with both serial and usb connection
     
     -1x 4 channel relay 5v

     -1x picamera
 
     -breadboard + gpio breakout
 
     -1x usb wifi dongle, 2x bluetooth usb
 
     -various sensors and bits

 
 **tooling**
 
    -soldering equipment
