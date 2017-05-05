# -*- coding: utf-8 -*-
"""Gevent server for nordichack

Setup:
- pip install gevent
- pip install Flask-Sockets

Running:
- python server.py
"""

import nordichack
from werkzeug.debug import DebuggedApplication

app = DebuggedApplication(nordichack.app, evalex=True)

if __name__ == "__main__":
    import gevent
    import gevent.signal
    from gevent import pywsgi, signal
    from geventwebsocket.handler import WebSocketHandler
    server = pywsgi.WSGIServer(('', 5000), app,
                               handler_class=WebSocketHandler)

    def shutdown():
        print('Shutting down ...')
        nordichack.shutdown()
        server.stop(timeout=10)
        exit(signal.SIGTERM)

    gevent.signal(signal.SIGTERM, shutdown)
    gevent.signal(signal.SIGINT, shutdown)
    server.serve_forever()
