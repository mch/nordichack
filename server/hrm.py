# -*- coding: utf-8 -*-

import sys
import time

from ant.core import driver, node, log
from ant.core.exceptions import DriverError
from ant.plus.heartrate import *

LOG = log.LogWriter()
DEBUG = True

class Hrm(object):
    def __init__(self):
        self.device = None
        self.antnode = None
        self.heartrate = None
        self.states = {STATE_SEARCHING: 'searching'
                       , STATE_SEARCH_TIMEOUT: 'search timeout'
                       , STATE_CLOSED: 'closed'
                       , STATE_RUNNING: 'running'}

        self.start_node()
        self.open_channel()

    def start_node(self):
        try:
            # TODO configuration of USB device
            self.device = driver.USB2Driver(log=LOG, debug=DEBUG)
            self.antnode = node.Node(self.device)

            self.antnode.start()
        except DriverError as e:
            print("Driver error")

    def open_channel(self):
        try:
            # TODO configuration of paired device
            self.heartrate = HeartRate(self.antnode)
        except Exception as e:
            print("Error opening channel")

    def get_heartrate(self):
        if self.heartrate and self.heartrate.state == STATE_RUNNING:
            return self.heartrate.computed_heart_rate
        return '--'

    def get_state(self):
        if self.heartrate:
            return self.states[self.heartrate.state]
        return '--'

    def close(self):
        self.antnode.stop()
