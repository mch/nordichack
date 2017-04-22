"""
Fake implementation in the event the ant library is not installed.
"""

class Hrm:
    def close(self):
        pass

    def get_heartrate(self):
        return None
