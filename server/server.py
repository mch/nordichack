# -*- coding: utf-8 -*-
"""Gevent server for nordichack

Setup:
- pip install gevent
- pip install Flask-Sockets

Running:
- python server.py
"""

from nordichack import app

if __name__ == "__main__":
    from gevent import pywsgi
    from geventwebsocket.handler import WebSocketHandler
    server = pywsgi.WSGIServer(('', 5000), app, handler_class=WebSocketHandler)
    server.serve_forever()
