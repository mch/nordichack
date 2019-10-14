#pragma once

#include <cmath>

class HardwareInterface
{
 public:
  virtual void init() = 0;
  virtual void shutdown() = 0;
  virtual void writePwm(int dutyCyclePercent) = 0;
  virtual int readSpeedFrequency() = 0;
};

class Gpio : public HardwareInterface
{
 public:
  Gpio();
  ~Gpio();

  void init();

  void shutdown();

  void writePwm(int dutyCyclePercent);

  int readSpeedFrequency();
};

class FakeGpio : public HardwareInterface
{
 public:
  void init()
  {}

  void shutdown()
  {}

  void writePwm(int dutyCyclePercent)
  {
    if (dutyCyclePercent == 0)
      {
	speed = 0;
      }
    else
      {
	speed = round(3.424 * dutyCyclePercent - 18.558);
      }
  }

  int readSpeedFrequency()
  {
    if (speed == 0)
      {
	return 0;
      }

    return round(1.93 * speed - 0.657);
  }

 private:
  int speed;

};
