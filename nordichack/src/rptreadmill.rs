use std::sync::mpsc::{Sender, Receiver};
use rppal::gpio::{self, Gpio, InputPin, OutputPin, Trigger, Level};
use rppal::pwm::{self, Pwm, Channel, Polarity};
use std::thread;
use std::time::{Duration};
use crate::treadmill::{Command, Event};

const GREEN_SPEED_SENSOR_GPIO_PIN: u8 = 17;
const BLUE_PWM_GPIO_PIN: u8 = 18;
const ORANGE_INCLINE_UP_GPIO_PIN: u8 = 27;
const YELLOW_INCLINE_DOWN_GPIO_PIN: u8 = 22;
const VIOLET_INCLINE_SENSOR_GPIO_PIN: u8 = 23;
const SAFETY_SWITCH_GPIO_PIN: u8 = 24;

struct TreadmillPins {
    speed_sensor_pin: InputPin,
    pwm: Pwm,
    incline_up_pin: OutputPin,
    incline_down_pin: OutputPin,
    incline_sensor_pin: InputPin,
    safety_pin: InputPin,
}

enum TreadmillError {
    GpioError(gpio::Error),
    PwmError(pwm::Error),
    GenericError(String),
}

impl From<gpio::Error> for TreadmillError {
    fn from(error: gpio::Error) -> Self {
        TreadmillError::GpioError(error)
    }
}

impl From<pwm::Error> for TreadmillError {
    fn from(error: pwm::Error) -> Self {
        TreadmillError::PwmError(error)
    }
}

impl std::fmt::Display for TreadmillError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> Result<(), std::fmt::Error> {
        match self {
            TreadmillError::GpioError(err) => {
                write!(f, "{}", err)
            },
            TreadmillError::PwmError(err) => {
                write!(f, "{}", err)
            },
            TreadmillError::GenericError(err) => {
                write!(f, "{}", err)
            }
        }
    }
}

fn set_up_pins(event_tx: &Sender<Event>) -> Result<TreadmillPins, TreadmillError> {
    // TODO reorganize this and improve the error handling. Map the rppal errors into
    // specific errors that tell me what part of this function failed, e.g. due to permissions.

    // Inputs to the Pi are pulled high by default, and the motor controller pulls them low to
    // generate a signal. Outputs from the Pi are low by default, setting them high causes stuff to
    // happen.
    let mut speed_sensor_pin = Gpio::new()?.get(GREEN_SPEED_SENSOR_GPIO_PIN)?.into_input_pullup();
    let speed_event_tx = event_tx.clone();
    let mut speed_count = 0;

    // TODO The interrupts are currently too noisy when the treadmill is running,
    // even the safety key one. Might need to add the filter caps back into the circuit.

    // speed_sensor_pin.set_async_interrupt(Trigger::FallingEdge, move |_level| {
    //     // What do we actually want to do with this information? It might not be relevant to the
    //     // user, and is more of a fail safe, e.g. if nothing is received here, the treadmill should
    //     // be stopped.
    //     speed_count += 1;
    //     speed_event_tx.send(Event::Msg(format!("Speed count: {}", speed_count)));
    // });

    let mut incline_sensor_pin = Gpio::new()?.get(VIOLET_INCLINE_SENSOR_GPIO_PIN)?.into_input_pullup();
    let incline_event_tx = event_tx.clone();
    let mut incline_count = 0;
    // incline_sensor_pin.set_async_interrupt(Trigger::FallingEdge, move |_level| {
    //     // What do we actually want to do with this information? It might not be relevant to the
    //     // user, and is more of a fail safe, e.g. if nothing is received here, the treadmill should
    //     // be stopped.
    //     incline_count += 1;
    //     incline_event_tx.send(Event::Msg(format!("Incline count: {}", speed_count)));
    // });

    // PWM to drive the treadmill
    let pwm = Pwm::new(Channel::Pwm0)?;
    pwm.disable();
    pwm.set_period(Duration::from_millis(50));
    pwm.set_pulse_width(Duration::from_millis(50));
    // This line is causing a OS error 22:
    // pwm.set_polarity(Polarity::Normal)?;

    let incline_up_pin = Gpio::new()?.get(ORANGE_INCLINE_UP_GPIO_PIN)?.into_output_low();
    let incline_down_pin = Gpio::new()?.get(YELLOW_INCLINE_DOWN_GPIO_PIN)?.into_output_low();

    // When the key is inserted, the safety switch closes to ground, and must be pulled high
    // otherwise.
    let mut safety_pin = Gpio::new()?.get(SAFETY_SWITCH_GPIO_PIN)?.into_input_pullup();
    let safety_event_tx = event_tx.clone();
    // safety_pin.set_async_interrupt(Trigger::Both, move |level| {
    //     // TODO immediately stop the treadmill.
    //     //pwm.disable(); // use of moved value
    //     if level == Level::High {
    //         safety_event_tx.send(Event::KeyRemoved);
    //     } else {
    //         safety_event_tx.send(Event::KeyInserted);
    //     }
    // });

    Ok(TreadmillPins {
        speed_sensor_pin, pwm, incline_up_pin, incline_down_pin, incline_sensor_pin, safety_pin,
    })
}

pub struct PiTreadmill {
    pins: TreadmillPins,
    command_rx: Receiver<Command>,
    event_tx: Sender<Event>,
}

impl PiTreadmill {
    pub fn new(command_rx: Receiver<Command>, event_tx: Sender<Event>) -> Result<PiTreadmill, String> {
        let pins = set_up_pins(&event_tx);
        pins.map(|pins| PiTreadmill { pins, command_rx, event_tx })
            .map_err(|err| err.to_string())
    }

    /**
     * Blocks waiting for commands.
     */
    pub fn run(self: &mut Self) {
        for command in self.command_rx.iter() {
            match command {
                Command::Start => {
                    self.pins.pwm.enable()
                        .and_then(|()| self.pins.pwm.set_period(Duration::from_millis(50)))
                        .and_then(|()| self.pins.pwm.set_duty_cycle(0.234))
                        .map_err(|err| TreadmillError::GenericError(err.to_string()))
                        .and_then(|()| self.event_tx.send(Event::SpeedSet(1.0))
                                  .map_err(|err| TreadmillError::GenericError(err.to_string())))
                        .or_else(|err| self.event_tx.send(Event::Msg(err.to_string())))
                        ;
                    self.event_tx.send(Event::Msg(format!("PWM Polarity: {:?}, period: {:?}, duty: {:?}",
                                                          self.pins.pwm.polarity(),
                                                          self.pins.pwm.period(),
                                                          self.pins.pwm.duty_cycle())));
                },
                Command::Stop => {
                    self.pins.pwm.set_duty_cycle(0.0);
                    self.pins.pwm.disable();
                    self.event_tx.send(Event::SpeedSet(0.0));
                },
                Command::SetSpeed(desiredSpeed) => {
                },
                Command::SpeedUp => {
                },
                Command::SlowDown => {
                },
                Command::Raise => {
                    // TODO check current incline, don't go too high
                    self.pins.incline_up_pin.toggle();
                    thread::sleep(Duration::from_millis(1000));
                    self.pins.incline_up_pin.toggle();
                },
                Command::Lower => {
                    // TODO check current incline, don't go too low
                    self.pins.incline_down_pin.toggle();
                    thread::sleep(Duration::from_millis(1000));
                    self.pins.incline_down_pin.toggle();
                },
                Command::Shutdown => {
                    break;
                }
            }
        }
    }
}

