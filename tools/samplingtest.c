#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <math.h>

#include <wiringPi.h>


#define PWM_PIN 18
#define SPEED_SENSE_PIN 17

// 19.2e6 Hz / CLOCK_DIVISOR / RANGE = 20 Hz
#define PWM_CLOCK_DIVISOR 3840
#define PWM_RANGE 250


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

  FILE* f = fopen("data.txt", "w");

  pwmWrite(PWM_PIN, 128);
  int i = 0;
  int last_rise_time = 0;

  // Wellford's method:
  int t_avg = 0;
  int k = 0;

  int last_t = 0;

  // Record the last second or so of samples and use that to compute the average speed.
  int MAX_T = 500;
  int* timings = (int*)malloc(sizeof(int)*MAX_T); // Store the period at each rising edge
  int start = 0;
  int end = 0;

  for (i = 0; i < 30; i++)
    {
      unsigned int start_ms = millis();
      int last_speed_level = digitalRead(SPEED_SENSE_PIN);
      unsigned int falling_transitions = 0;
      unsigned int rising_transitions = 0;
      unsigned int samples = 0;
      end = 0;


      while (millis() - start_ms < 1000)
	{
	  delay(2); // ms
	  int speed_level = digitalRead(SPEED_SENSE_PIN);
	  unsigned int time_us = micros();
	  fprintf(f, "%d %d\n", time_us, speed_level);
	  samples++;

	  if (last_speed_level < speed_level)
	    {
	      rising_transitions++;

	      // Wellford's method
	      k++;
	      int t = time_us - last_rise_time;
	      last_rise_time = time_us;
	      last_t = t;

	      t_avg = t_avg + (t - t_avg) / k;

	      timings[end] = t;
	      end++;
	      if (end >= MAX_T)
		end = 0;
	    }
	  else if (last_speed_level > speed_level)
	    falling_transitions++;

	  last_speed_level = speed_level;
	}

      int t_avg2 = 0;
      int j = 0;
      for (j = 0; j < end; j++)
	{
	  t_avg2 = t_avg2 + (timings[j] - t_avg2) / (j+1);
	}

      if (t_avg2 > 0)
	printf("t_avg2: %d, Speed: %f\n", t_avg2, 0.517 * (1.0 / (t_avg2 / 1000000.0)) + 0.353);
      //printf("Freq: %d\n", falling_transitions);
      //printf("samples: %d, falling: %d, rising: %d\n", samples, falling_transitions, rising_transitions);
      /* if (last_t > 0) */
      /* 	printf("last_t: %d, Speed: %f\n", last_t, 0.517 * (1.0 / (last_t / 1000000.0)) + 0.353); */

      if (t_avg > 0)
	printf("t_avg: %d, Speed: %f\n", t_avg, 0.517 * (1.0 / (t_avg / 1000000.0)) + 0.353);
    }

  fclose(f);
  pwmWrite(PWM_PIN, 0);

  //  printf("Number of pulses detected: %d\n", counter);

  return 0;
}
