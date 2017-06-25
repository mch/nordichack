# -*- coding: utf-8 -*-
"""Handles ANT devices

There should only evern be one instance of the AntDevices class, since
it talks to a hardware device.

- Strives to keep a device connected
- Runs the Node object
- Caches channels or ANT+ objects for specific devices
"""

import sys
import time

from gevent.queue import Queue, Full

from ant.core import driver, node, log
from ant.core.exceptions import DriverError
from ant.plus.heartrate import *

class HrmCallback(HeartRateCallback):

    def __init__(self, queue):
        self.queue = queue

    def device_found(self, device_number, transmission_type):
        pass

    def heartrate_data(self, computed_heartrate, rr_interval_ms): # rest to come soon
        try:
            self.queue.put_nowait((computed_heartrate, rr_interval_ms))
        except Full:
            print("warning: consumer not reading hr messages from queue")

class AntDevices(object):
    def __init__(self):
        self.usb_device = None
        self.node = None
        self.devices = {}

    def start(self): # todo USB device configuration input
        try:
            print("Opening USB...")
            self.usb_device = driver.USB2Driver(debug=True, idProduct=0x1009)
            print("Got USB: {0}".format(self.usb_device))
        except DriverError as e:
            print("Unable to open USB device.")
            return
        except Exception as e:
            print("Unexpected exception: {0}".format(e))
            return

        try:
            print("Creating node...")
            self.node = node.Node(self.usb_device)
            print("Starting node {0}".format(self.node))
            self.node.start()
            print("node started.")
        except Exception as e:
            self.node = None
            print("Unable to start node: {0}".format(e))


    def stop(self):
        if self.node and self.node.running:
            self.node.stop()


    def open_heartrate_device(self, device_number, transmission_type):
        if not (self.usb_device and self.node):
            print("Unable to open hr device, no usb device or node.")
            return None

        if not self.node.running:
            print("Unable to open hr device, node not running.")
            return None

        key = (device_number, transmission_type)
        if key in self.devices:
            print("Found existing hr device.")
            return self.devices[key]

        try:
            # TODO make this a class
            device = {}
            device['queue'] = Queue(maxsize=1)
            device['callback'] = HrmCallback(device['queue'])
            device['object'] = HeartRate(self.node, callback = device['callback'])

            self.devices[key] = device
        except:
            print("Unable to open heart rate device.")
            device = None

        return device
