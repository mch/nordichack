#include <time.h>
#include <stdio.h>
#include <inttypes.h>
#include <math.h>

#include <wiringPi.h>


#define PWM_PIN 18
#define SPEED_SENSE_PIN 17

// 19.2e6 Hz / CLOCK_DIVISOR / RANGE = 20 Hz
#define PWM_CLOCK_DIVISOR 3840
#define PWM_RANGE 250

volatile int counter = 0;
volatile int frequency = 0;
struct timespec startTime;

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

int main(int argc, char** argv)
{
  if (wiringPiSetupGpio() < 0)
    {
      printf("Unable to set up wiringPi\n");
      return 1;
    }

  pinMode(PWM_PIN, PWM_OUTPUT);
  pwmSetMode(PWM_MODE_MS);
  pwmSetClock(3840);
  pwmSetRange(250);

  pinMode(SPEED_SENSE_PIN, INPUT);
  pullUpDnControl(SPEED_SENSE_PIN, PUD_UP);

  int current = digitalRead(17);

  printf("Current value of input pin: %d\n", current);

  wiringPiISR(SPEED_SENSE_PIN, INT_EDGE_RISING, &pulse);

  clock_gettime(CLOCK_MONOTONIC, &startTime);
  pwmWrite(PWM_PIN, 60);
  int i = 0;
  for (i = 0; i < 10; i++)
    {
      sleep(1);
      printf("Freq: %d\n", frequency);
    }
  pwmWrite(PWM_PIN, 0);
  
  printf("Number of pulses detected: %d\n", counter);
  
  return 0;
}
