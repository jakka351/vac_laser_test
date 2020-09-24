# vac_laser_test

edit at will

jack contact details +61434645485 bjakkaleighton@gmail.com 

Dri-Sump Containment Tightness Testing Brainstorm

                Negative Pressure Vacuum Test
                -view chamber results -> see laser dot = pass
                -----------------------> see laser line = fail


     retrofit rpi to 'digitise' device.
     ---control of laser via gpio + relay--?
     ---gps lat/long logged
     ---timestamped photo taken of each test/result/use, sent off to technicians laptop & remote server
     ---usage counter & statistics 
     ---network connectivity, site wifi, ethernet, bluetooth serial/PAN,4Glte connectivity?
     ---phone app?
     ---cybersecurity?
     ---are electronics going to be exposed to vacuum?
     ---protective sealed case for dust and wear and tear
     
     

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
