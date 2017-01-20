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
    PASSWORD='admin',
    #ZMQ='tcp://localhost:5555'
    ZMQ='fake'
))
app.config.from_envvar('NORDICHACK_SETTINGS', silent=True)

def connect_db():
    """Connects to the specific database."""
    rv = sqlite3.connect(app.config['DATABASE'])
    rv.row_factory = sqlite3.Row
    return rv

class FakeSocket:
    def __init__(self):
        pass

    def send(self, msg):
        print "fake socket msg '%s'" % (msg,)

    def recv(self):
        return "OK"

    def close(self):
        pass

def get_socket():
    s = getattr(g, '_socket', None)
    if s is None:
        s = g._socket = FakeSocket()

        #c = g._context = zmq.Context()
        #s = g._socket = c.socket(zmq.REQ)
        #s.connect("tcp://localhost:5555") # todo use configuration

    return s

@app.teardown_appcontext
def close_socket(exception):
    s = getattr(g, '_socket', None)
    if s is not None:
        s.close()

    c = getattr(g, '_context', None)
    if c is not None:
        # ??
        pass

@app.route('/')
def hello():
    return render_template('index.html')

@app.route('/controller')
def controller():
    return render_template('controller.html')

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
            response = app.make_response(("Invalid speed requested", 400, []))
            response.mimetype = "text/plain"
            return response

        data = set_desired_speed(float(request.data))
    else:
        data = "0.0"

    response = app.make_response(data)
    response.mimetype = "text/plain"

    return response

def set_desired_speed(speed):

    # load calibration params from database
    slope = 3.424
    offset = 18.558
    dutycycle = int(speed * slope + offset)

    if speed == 0.0:
        dutycycle = 0

    # a "service" for handling sending zmq requests?
    s = get_socket()

    # this blocks indefinitly...
    s.send(b"SETDUTYCYCLE %d" % dutycycle)
    msg = s.recv()
    print("reply: '%s'" % (msg, ))
    return msg

