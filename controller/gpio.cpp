
#include "gpio.h"

#include <iostream>
#include <stdexcept>
#include <ctime>
#include <cmath>

#include <wiringPi.h>

#define PWM_PIN 18
#define SPEED_SENSE_PIN 17

// 19.2e6 Hz / CLOCK_DIVISOR / RANGE = 20 Hz
#define PWM_CLOCK_DIVISOR 3840
#define PWM_RANGE 250

static volatile int counter = 0;
static volatile int frequency = 0;
static struct timespec startTime;

extern "C" {

long getMillisecondsSinceStart()
{
  struct timespec currentTime;
  clock_gettime(CLOCK_MONOTONIC, &currentTime);

  time_t elapsedSeconds = currentTime.tv_sec - startTime.tv_sec;
  long elapsedNanoSeconds = currentTime.tv_nsec - startTime.tv_nsec;
  
  return lround(elapsedSeconds * 1.0e3) + lround(elapsedNanoSeconds / 1.0e6);
}

void pulse(void)
{
  counter++;

  long msSinceStart = getMillisecondsSinceStart();
  if (msSinceStart > 1000)
    {
      frequency = round(counter / (msSinceStart / 1.0e3));
      clock_gettime(CLOCK_MONOTONIC, &startTime);
      counter = 0;
    }
}
}

Gpio::Gpio()
{}

Gpio::~Gpio()
{
  shutdown();
}

void Gpio::init()
{
  if (wiringPiSetupGpio() < 0)
    {
      std::cerr << "Unable to set up wiringPi" << std::endl;
      throw std::runtime_error("Unable to set up wiringPi");
    }

  pinMode(PWM_PIN, PWM_OUTPUT);
  pwmSetMode(PWM_MODE_MS);
  pwmSetClock(3840);
  pwmSetRange(250);

  pinMode(SPEED_SENSE_PIN, INPUT);
  pullUpDnControl(SPEED_SENSE_PIN, PUD_UP);

  wiringPiISR(SPEED_SENSE_PIN, INT_EDGE_RISING, &pulse);

  clock_gettime(CLOCK_MONOTONIC, &startTime);
}
  
void Gpio::shutdown()
{
  pwmWrite(PWM_PIN, 0);
}
  
void Gpio::writePwm(int dutyCyclePercent)
{
  if (dutyCyclePercent < 0 || dutyCyclePercent > 100)
    {
      throw std::range_error("Duty cycle must be in the range 0 <= dutyCyclePercent <= 100.");
    }
  
  pwmWrite(PWM_PIN, round(dutyCyclePercent * 2.55));
}

int Gpio::readSpeedFrequency()
{
  return frequency;
}
