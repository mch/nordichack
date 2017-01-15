import os
import sqlite3
import zmq

from flask import Flask, request, session, g, redirect, url_for, abort, \
     render_template, flash

app = Flask(__name__) 
app.config.from_object(__name__) 

# Load default config and override config from an environment variable
app.config.update(dict(
    DATABASE=os.path.join(app.root_path, 'nordichack.db'),
    SECRET_KEY='development key',
    USERNAME='admin',
    PASSWORD='admin'
))
app.config.from_envvar('NORDICHACK_SETTINGS', silent=True)

def connect_db():
    """Connects to the specific database."""
    rv = sqlite3.connect(app.config['DATABASE'])
    rv.row_factory = sqlite3.Row
    return rv

@app.route('/')
def hello_world():
    return 'Hello, World!'

@app.route('/api/v1/desiredspeed', methods=['GET', 'POST'])
def desiredspeed():
    if request.method == 'POST':
        speed = None
        try:
            speed = float(request.data)
            if speed < 0.0 or speed > 30.0:
                speed = None
        except ValueError:
            speed = None

        if speed is None:
            return flask.Response(response = "Invalid speed requested",
                                  status = 400,
                                  headers = None,
                                  mimetype = "text/plain")
        
        set_desired_speed(float(request.data))
    else:
        return "0.0"    

def set_desired_speed(speed):

    # load calibration params from database
    slope = 3.424
    offset = 18.558
    dutycycle = int(speed * slope + offset)

    if speed == 0.0:
        dutycycle = 0
    
    # a "service" for handling sending zmq requests?
    c = zmq.Context()
    s = c.socket(zmq.REQ)
    s.connect("tcp://localhost:5555")
    s.send(b"SETDUTYCYCLE %d" % dutycycle)
    msg = s.recv()
    print("reply: '%s'" % (msg, ))

