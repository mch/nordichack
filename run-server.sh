#!/bin/bash

cd server
. venv/bin/activate
export FLASK_APP=nordichack.py
export FLASK_DEBUG=1

python server.py

deactivate
cd ..
