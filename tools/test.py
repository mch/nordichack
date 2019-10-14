import wiringpi
import time

PWM_PIN = 18
SPEED_SENSE_PIN = 17

# 19.2e6 Hz / CLOCK_DIVISOR / RANGE = 20 Hz
PWM_CLOCK_DIVISOR = 3840
PWM_RANGE = 250

class PwmCommand:
    def __init__(self, dutyCycle):
        if dutyCycle < 0 || dutyCycle > 255:
            dutyCycle = 0

        self.dutyCycle = dutyCycle

    def execute():
        wiringpi.pwmWrite(PWM_PIN, self.dutyCycle)


def init():
    wiringpi.wiringPiSetupGpio()

    wiringpi.pinMode(PWM_PIN, wiringpi.PWM_OUTPUT)
    wiringpi.pwmSetMode(wiringpi.PWM_MODE_MS)
    wiringpi.pwmSetClock(3840)
    wiringpi.pwmSetRange(250)

    wiringpi.pinMode(SPEED_SENSE_PIN, wiringpi.INPUT)
    wiringpi.pullUpDnControl(SPEED_SENSE_PIN, PUD_DOWN)

def cleanup():
   wiringpi.digitalWrite(PWM_PIN, 0)
   wiringpi.pinMode(PWM_PIN, wiringpi.INPUT)


def setDesiredSpeedKph(speedKph):

    OFFSET = 18.558
    SLOPE = 3.424

    MIN_SPEED = 2.0
    MAX_SPEED = 20.0

    if speedKph < MIN_SPEED || speedKph > MAX_SPEED:
        return

    dutyCycle = speedKph * SLOPE + OFFSET

    if speedKph == 0.0:
        dutyCycle = 0.0

    binaryDutyCycle = int(round(dutyCycle * 2.55))

    return PwmComment(binaryDutyCycle)


init()
setDesiredSpeedKph(2.0)

time.sleep(10)

setDesiredSpeedKph(0.0)

cleanup()
