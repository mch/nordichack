import wiringpi
import time

PWM_PIN = 18
SPEED_SENSE_PIN = 17
INCLINE_UP_PIN = 21
INCLINE_DOWN_PIN = 20
INCLINE_SENSE_PIN = 16

# 19.2e6 Hz / CLOCK_DIVISOR / RANGE = 20 Hz
PWM_CLOCK_DIVISOR = 3840
PWM_RANGE = 250

class PwmCommand:
    def __init__(self, dutyCycle):
        if dutyCycle < 0 or dutyCycle > 255:
            dutyCycle = 0

        self.dutyCycle = dutyCycle

    def execute():
        wiringpi.pwmWrite(PWM_PIN, self.dutyCycle)

last_change_at = 0
def incline_sense_callback():
    global last_change_at
    current = wiringpi.millis()
    diff = current - last_change_at
    last_change_at = current
    
    print("Incline changing! Time: %d, diff: %d" % (current, diff))
        
def init():
    wiringpi.wiringPiSetupGpio()

    wiringpi.pinMode(PWM_PIN, wiringpi.PWM_OUTPUT)
    wiringpi.pwmSetMode(wiringpi.PWM_MODE_MS)
    wiringpi.pwmSetClock(3840)
    wiringpi.pwmSetRange(250)

    wiringpi.pinMode(SPEED_SENSE_PIN, wiringpi.INPUT)
    wiringpi.pullUpDnControl(SPEED_SENSE_PIN, wiringpi.PUD_DOWN)

    wiringpi.pinMode(INCLINE_UP_PIN, wiringpi.OUTPUT)
    wiringpi.pullUpDnControl(INCLINE_UP_PIN, wiringpi.PUD_DOWN)

    wiringpi.pinMode(INCLINE_DOWN_PIN, wiringpi.OUTPUT)
    wiringpi.pullUpDnControl(INCLINE_DOWN_PIN, wiringpi.PUD_DOWN)

    wiringpi.pinMode(INCLINE_SENSE_PIN, wiringpi.INPUT)
    wiringpi.pullUpDnControl(INCLINE_SENSE_PIN, wiringpi.PUD_UP)
    wiringpi.wiringPiISR(INCLINE_SENSE_PIN, wiringpi.INT_EDGE_BOTH, incline_sense_callback)
    
def cleanup():
   wiringpi.digitalWrite(PWM_PIN, 0)
   wiringpi.pinMode(PWM_PIN, wiringpi.INPUT)
 

def setDesiredSpeedKph(speedKph):

    OFFSET = 18.558
    SLOPE = 3.424

    MIN_SPEED = 2.0
    MAX_SPEED = 20.0

    if speedKph < MIN_SPEED or speedKph > MAX_SPEED:
        return

    dutyCycle = speedKph * SLOPE + OFFSET

    if speedKph == 0.0:
        dutyCycle = 0.0

    binaryDutyCycle = int(round(dutyCycle * 2.55))

    return PwmComment(binaryDutyCycle)


def test_speed():
    setDesiredSpeedKph(2.0)
    time.sleep(10)
    setDesiredSpeedKph(0.0)

def wait_for_incline_stop():
    global last_change_at
    done = False
    while not done:
        wiringpi.delay(500)
        current = wiringpi.millis();
        diff = current - last_change_at
        print('Checking if we should stop at %d, diff %d' % (current, diff))
        if diff > 800:
            done = True
    
def test_incline_up():
    global last_change_at
    print('Incline up...')
    wiringpi.digitalWrite(INCLINE_UP_PIN, 1)
    wait_for_incline_stop()
    print('Incline stop')
    wiringpi.digitalWrite(INCLINE_UP_PIN, 0)
    print('Incline down')
    wiringpi.digitalWrite(INCLINE_DOWN_PIN, 1)
    last_change_at = wiringpi.millis()
    wait_for_incline_stop()
    print('Incline stop')
    wiringpi.digitalWrite(INCLINE_DOWN_PIN, 0)
    
try:
    print('Calling init()...')
    init()
    # test_speed()
    test_incline_up()
    print('Calling cleanup()...')
    cleanup()
except Exception as e:
    print('Something went wrong.')
    print(e)
