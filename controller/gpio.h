#pragma once

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
  {}

  int readSpeedFrequency()
  {}
  
};
