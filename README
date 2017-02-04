# NordicHack

This project implements a controller and web interface for treadmills that use
the MC2100LTS-30 motor controller board (Icon part number [263165]()). This likely
includes many Icon Fitness treadmills under various brand names such as
Epic, NordicTrack, Proform, Reebok, and probably others. Use the part search
form at [Icon Service Canada](https://www.iconservice.ca/CustomerService/parts)
or [Icon Service](https://www.iconservice.com/CustomerService/parts.do) to
search for part number 263165 to see if your model might work.

The long term goal is to allow for control of treadmill speed and incline, easy
contruction of traing programs, and recording fitness data, including heart rate
(via a USB ANT+ dongle).

# Interface hardware

todo: schematics

# Components

This project is a suite of three pieces of software.

## Controller

The controller program is written in C++ and is responsible for interacting with
the GPIO pins. It has a minimum of logic, being responsible only for
calculations directly related to controlling the speed and incline of the
treadmill, as well as features related to safe operations of the hardware, such
as ensuring the key is in the console before allowing operation and stopping the
motors if no feedback on their motion is available.

The controller program uses ZeroMQ to communicate with the web server.

## Webserver

The webserver is currently written in Python using Flask. This part is
responsible for serving static resources such as the UI, storing
information in a database to facilitate the construction of training
programs and recording runs.

## UI

The front end is written in Elm. Unfortunately the Elm compiler is not available
on the Raspberry Pi, so it is necessary to build the frontend on a Windows, Mac,
or Linux machine.

# Installing

Install the required dependencies:
```
sudo apt-get install wiringpi libzmq3-dev python-zmq
sudo pip install wiringpi2
```

This project currently uses Flask for it's web server. Flask can be set up

```
cd server
pip install virtualenv
virtualenv venv
. venv/bin/activate
pip install flask
pip install pyzmq
export FLASK_APP=nordichack.py
export FLASK_DEBUG=1
deactivate
```

Once that is set up, you can run the web server using the provided
`run-server.sh` script.
