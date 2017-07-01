# -*- coding: utf-8 -*-
import os
import time
from datetime import datetime

from gevent import Greenlet, joinall
from gevent.queue import Queue, Empty
from geventwebsocket.exceptions import WebSocketError

import data
import treadmill

from antdevices import AntDevices

import flask
from flask import Flask, request, session, g, redirect, url_for, abort, \
     render_template, flash

from flask_sockets import Sockets

app = Flask(__name__)
sockets = Sockets(app)
app.config.from_object(__name__)

# Load default config and override config from an environment variable
app.config.update(dict(
    DATABASE=os.path.join(app.root_path, 'nordichack.db'),
    SECRET_KEY='development key',
    USERNAME='admin',
    PASSWORD='admin',
    #ZMQ='tcp://localhost:5555'
    ZMQ='fake',
    #ANT_USB_PRODUCTID='fake',
    ANT_USB_PRODUCTID=0x1009,
    ANT_HR_DEVICE_NUM=23358,
    ANT_HR_TRANS_TYPE=1
))
app.config.from_envvar('NORDICHACK_SETTINGS', silent=True)

def get_treadmill():
    if not hasattr(g, 'treadmill'):
        g.treadmill = treadmill.connect_treadmill(app.config['ZMQ'])
    return g.treadmill

def get_db():
    if not hasattr(g, 'data'):
        g.data = data.Data(app.config['DATABASE'])
    return g.data

ant_devices = None
def get_ant_devices():
    global ant_devices
    if ant_devices is None:
        print("creating ant devices")
        try:
            ant_devices = AntDevices(app.config['ANT_USB_PRODUCTID'])
            ant_devices.start()
        except Exception as e:
            print("Unable to start ant node. Ensure USB key is connected are restart server.")
            print("Unexpected exception: {0}".format(e))
            pass

    return ant_devices

@app.cli.command('initdb')
def initdb_command():
    """Creates the database tables"""
    d = get_db()
    d.init_db(app.open_resource('schema.sql', mode='r'))
    print("Initialized the database.")

@app.teardown_appcontext
def close_treadmill(exception):
    if hasattr(g, 'treadmill'):
        g.treadmill.close()

@app.teardown_appcontext
def close_db(error):
    if hasattr(g, 'data'):
        g.data.close()

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

        treadmill = get_treadmill()
        data = treadmill.set_desired_speed(float(request.data))
        print("DATA: " + str(data))
    else:
        data = "0.0"

    response = app.make_response(data)
    response.mimetype = "text/plain"

    return response

@app.route('/api/v1/runs', methods=['GET', 'POST'])
def runs():
    response = None

    if request.method == 'POST':
        # [{time: int, speed: int}]
        d = flask.json.loads(request.data)
        # TODO The time should be the time the run starts, not when it ends
        try:
            result = get_db().save_new_run("Untitled Run", str(datetime.now()), d)
            response = json_response(result)
        except:
            response = internal_server_error("Unable to save run")

    else:
        try:
            response = json_response(get_db().get_runs())

        except:
            response = internal_server_error("Unable to retrieve runs")

    return response

def internal_server_error(message):
    data = flask.json.jsonify({"message": message})
    response = app.make_response((data, 500, []))
    response.mimetype = "application/json"
    return response

def json_response(data):
    response = app.make_response(flask.json.jsonify(data))
    response.mimetype = "application/json"
    return response

@app.route('/api/v1/heartrate', methods=['GET'])
def heartrate():
    ant_devices = get_ant_devices()
    hrm_device = ant_devices.open_heartrate_device(app.config['ANT_HR_DEVICE_NUM'],
                                                   app.config['ANT_HR_TRANS_TYPE'])
    if hrm_device:
        hrm = hrm_device['object']
        return json_response({'heartrate': hrm.computed_heartrate()})

    return json_response({'heartrate': '--'})

@sockets.route('/heartrate')
def heartrate_socket(ws):
    ant_devices = get_ant_devices()
    if not ant_devices:
        print("No ANT+ USB device available.")
        return

    hrm_device = ant_devices.open_heartrate_device(app.config['ANT_HR_DEVICE_NUM'],
                                                   app.config['ANT_HR_TRANS_TYPE'])
    if not hrm_device:
        print("No hrm device available.")
        return

    def watch_for_socket_close():
        while not ws.closed:
            # reading seems to be necessary to detect socket close in
            # a timely fashion
            data = ws.receive()

    read_greenlet = Greenlet.spawn(watch_for_socket_close)

    q = hrm_device['queue']
    event_time_ms = 0

    while not ws.closed:
        try:
            hr, event_time_s, rr_interval = q.get(timeout=0.2) # why is a timeout necessary?

            json_str = {'heartrate_bpm': hr}

            if rr_interval is not None:
                json_str = {'heartrate_bpm': hr, 'rr_interval_ms': rr_interval, 'event_time_s': event_time_s}

            msg = flask.json.dumps(json_str)
            ws.send(msg)
        except Empty:
            pass
        except WebSocketError as e:
            print("websocket error: " + str(e))
            break;

    read_greenlet.join()


def shutdown():
    global ant_devices
    if ant_devices:
        print("stopping ant devices.")
        ant_devices.stop()
