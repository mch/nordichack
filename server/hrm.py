"""
Based on
https://github.com/baderj/python-ant/blob/develop/demos/ant.core/04-processevents.py
"""

import sys
import time

from ant.core import driver
from ant.core import node
from ant.core import event
from ant.core import message
from ant.core.constants import *

from config import *

NETKEY = '\xB9\xA5\x21\xFB\xBD\x72\xC3\x45'

class Listener(event.EventCallback):

    def __init__(self, callback):
        self.callback = callback

    def process(self, msg):
        if isinstance(msg, message.ChannelBroadcastDataMessage):
            self.callback(ord(msg.payload[-1]))

class Hrm:

    def __init__(self):
        self.stick = driver.USB2Driver(SERIAL, log=LOG, debug=DEBUG)
        self.node = node.Node(stick)
        self.node.start()

        self.key = node.NetworkKey('N:ANT+', NETKEY)
        self.node.setNetworkKey(0, key)
        self.channel = self.node.getFreeChannel()
        self.channel.name = 'C:HRM'
        self.channel.assign('N:ANT+', CHANNEL_TYPE_TWOWAY_RECEIVE)
        self.channel.setID(120, 0, 0)
        self.channel.setSearchTimeout(TIMEOUT_NEVER)
        self.channel.setPeriod(8070)
        self.channel.setFrequency(57)
        self.channel.open()

        self.heartrate = None

        def callback(rate):
            self.heartrate = rate

        self.channel.registerCallback(Listener(callback))

    def close(self):
        self.channel.close()
        self.channel.unassign()
        self.node.stop()

    def get_heartrate():
        return self.heartrate
