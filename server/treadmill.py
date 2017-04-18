import zmq

class Treadmill:

    def __init__(self, path):
        if path == 'fake':
            self.socket = FakeSocket()
        else:
            self.socket = ZmqSocket(path)

    def set_desired_speed(self, speed):
        dutycycle = self.compute_dutycycle(speed)
        return self.send_message(b"SETDUTYCYCLE %d" % dutycycle)

    def compute_dutycycle(self, speed):
        if speed == 0.0:
            return 0

        # todo: load calibration params from database
        slope = 3.424
        offset = 18.558
        return int(speed * slope + offset)

    def send_message(self, msg):
        # this blocks indefinitly...
        self.socket.send(msg)
        msg = self.socket.recv()
        print("reply: '%s'" % (msg, ))
        return msg

    def close(self):
        self.socket.close()

class TreadmillSocket:
    pass

class FakeSocket(TreadmillSocket):
    def __init__(self):
        pass

    def send(self, msg):
        print "fake socket msg '%s'" % (msg,)

    def recv(self):
        return "OK"

    def close(self):
        pass

class ZmqSocket(TreadmillSocket):
    def __init__(self, path):
        self.context = zmq.Context()
        self.socket = c.socket(zmq.REQ)
        s.connect(path)

    def send(self, msg):
        self.socket.send(msg)

    def recv(self):
        return self.socket.recv()

    def close(self):
        self.socket.close()
        # self.context....

def connect_treadmill(path):
    return Treadmill(path)
