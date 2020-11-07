# vac_laser_test

![alt text](https://github.com/jakka351/vac_laser_test/blob/master/_updatebluetoothrasp.png?raw=true)Mock up drawing of RPI3

**ssh over bluetooth**
  
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

![alt text](https://github.com/jakka351/vac_laser_test/blob/bluetooth/images/20201105_093431.jpg?raw=true)Sample

jack contact details +61434645485 bjakkaleighton@gmail.com 

**Dri-Sump Containment Tightness Testing Brainstorm**

                Negative Pressure Vacuum Test
                -view chamber results -> see laser dot = pass
                -----------------------> see laser line = fail
               
                
**22/10/2020 - rpi to have own gps unit,  can use ublox modules same as tardis, gpsd **
   
   **read only file system to help avoid sd card corruption **           

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

