import os

import data
import treadmill

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

def get_treadmill():
    if not hasattr(g, 'treadmill'):
        g.treadmill = treadmill.connect_treadmill(app.config['ZMQ'])
    return g.treadmill

def get_db():
    if not hasattr(g, 'sqlite_db'):
        g.sqlite_db = data.connect_db(app.config['DATABASE'])
    return g.sqlite_db

@app.cli.command('initdb')
def initdb_command():
    """Creates the database tables"""
    data.init_db(get_db(), app.open_resource('schema.sql', mode='r'))
    print("Initialized the database.")

@app.teardown_appcontext
def close_treadmill(exception):
    if hasattr(g, 'treadmill'):
        g.treadmill.close()

@app.teardown_appcontext
def close_db(error):
    if hasattr(g, 'sqlite_db'):
        g.sqlite_db.close()

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
        print "DATA: " + str(data)
    else:
        data = "0.0"

    response = app.make_response(data)
    response.mimetype = "text/plain"

    return response

@app.route('/api/v1/runs', methods=['GET', 'POST'])
def runs():
    if request.method == 'POST':
        #save_new_run(request.data)
        pass
    else:
        get_runs()


