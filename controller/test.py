import zmq
c = zmq.Context()
s = c.socket(zmq.REQ)
s.connect("tcp://localhost:5555")
s.send(b"SETDUTYCYCLE adsf")
msg = s.recv()
print("reply: '%s'" % (msg, ))
