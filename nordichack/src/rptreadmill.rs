use std::sync::mpsc::{Sender, Receiver};
use rppal::gpio::{self, Gpio, InputPin, OutputPin, Trigger, Level};
use rppal::pwm::{self, Pwm, Channel, Polarity};
use std::thread;
use std::time::{Duration, Instant};
use crate::treadmill::{Command, Event};
use crate::treadmill;

const GREEN_SPEED_SENSOR_GPIO_PIN: u8 = 17;
const BLUE_PWM_GPIO_PIN: u8 = 18;
const ORANGE_INCLINE_UP_GPIO_PIN: u8 = 27;
const YELLOW_INCLINE_DOWN_GPIO_PIN: u8 = 22;
const VIOLET_INCLINE_SENSOR_GPIO_PIN: u8 = 23;
const SAFETY_SWITCH_GPIO_PIN: u8 = 24;

const PWM_PERIOD: Duration = Duration::from_millis(50);

struct TreadmillPins {
    //speed_sensor_pin: InputPin,
    pwm: Pwm,
    incline_up_pin: OutputPin,
    incline_down_pin: OutputPin,
    incline_sensor_pin: InputPin,
    //safety_pin: InputPin,
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
    // let mut speed_sensor_pin = Gpio::new()?.get(GREEN_SPEED_SENSOR_GPIO_PIN)?.into_input_pullup();
    // let speed_event_tx = event_tx.clone();
    // let mut speed_count = 0;

    // TODO The interrupts are currently too noisy when the treadmill is running, even the safety
    // key one. Might need to add the filter caps back into the circuit, or poll those pins instead.

    // speed_sensor_pin.set_async_interrupt(Trigger::FallingEdge, move |_level| {
    //     // What do we actually want to do with this information? It might not be relevant to the
    //     // user, and is more of a fail safe, e.g. if nothing is received here, the treadmill should
    //     // be stopped.
    //     speed_count += 1;
    //     speed_event_tx.send(Event::Msg(format!("Speed count: {}", speed_count)));
    // });

    let mut incline_sensor_pin = Gpio::new()?.get(VIOLET_INCLINE_SENSOR_GPIO_PIN)?.into_input_pulldown();
    // let incline_event_tx = event_tx.clone();
    // let mut incline_count = 0;
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
    pwm.set_period(PWM_PERIOD);
    pwm.set_pulse_width(Duration::from_millis(50));
    // This line is causing a OS error 22:
    // pwm.set_polarity(Polarity::Normal)?;

    let incline_up_pin = Gpio::new()?.get(ORANGE_INCLINE_UP_GPIO_PIN)?.into_output_low();
    let incline_down_pin = Gpio::new()?.get(YELLOW_INCLINE_DOWN_GPIO_PIN)?.into_output_low();

    // When the key is inserted, the safety switch closes to ground, and must be pulled high
    // otherwise.
    // let mut safety_pin = Gpio::new()?.get(SAFETY_SWITCH_GPIO_PIN)?.into_input_pullup();
    // let safety_event_tx = event_tx.clone();
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
        /*speed_sensor_pin,*/ pwm, incline_up_pin, incline_down_pin, incline_sensor_pin//, safety_pin,
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
     * Start a new thread that polls inputs, updating state and sending events when things change.
     */
    pub fn watch_inputs(self: &mut Self) {
        let event_tx = self.event_tx.clone();
        let t = thread::spawn(move || {
            // Shannon's sampling theorem:
            // 𝑓ₛ ≥ 2𝑊

            // Should I be able to use a single Gpio? Multiple and_then results in moving the value,
            // and as_ref() causes errors I don't understand.
            let gpio = Gpio::new();
            let safety_pin = Gpio::new()
                .and_then(|gpio| gpio.get(SAFETY_SWITCH_GPIO_PIN))
                .map(|pin| pin.into_input_pullup());

            let speed_pin = gpio
                .and_then(|gpio| gpio.get(GREEN_SPEED_SENSOR_GPIO_PIN))
                .map(|pin| pin.into_input_pullup());

            if safety_pin.is_err() || speed_pin.is_err() {
                // log message
                return;
            }

            // Are there better ways to handle multiple values in Results?
            let safety_pin = safety_pin.unwrap();
            let speed_pin = speed_pin.unwrap();

            let mut safety_pin_level = safety_pin.read();
            let mut speed_pin_level = speed_pin.read();
            let mut speed_pin_transition_high_instant = Instant::now();

            loop {
                let current_level = safety_pin.read();
                if current_level != safety_pin_level {
                    safety_pin_level = current_level;

                    let r = if current_level == Level::High {
                        // What's the best way to get this back to the main treadmill thread so that
                        // it can stop the treadmill? Don't want to round trip to the UI. Do I need
                        // ANOTHER thread to merge the commands from the UI with this KeyRemoved
                        // event? Probably best to pass a command_tx clone from main into here.
                        event_tx.send(Event::KeyRemoved)
                    } else {
                        event_tx.send(Event::KeyInserted)
                    };
                    if r.is_err() {
                        // logfile?
                        break;
                    }
                }

                let current_speed_pin_level = speed_pin.read();
                let current_speed_pin_read_instant = Instant::now();
                if current_speed_pin_level != speed_pin_level {
                    if speed_pin_level == Level::High {
                        let period_ms = speed_pin_transition_high_instant.elapsed().as_millis();
                        //event_tx.send(Event::Msg(format!("Speed pin period: {} ms", period_ms)));
                        speed_pin_transition_high_instant = current_speed_pin_read_instant;

                        let period_sec = speed_pin_transition_high_instant.elapsed().as_secs_f32();
                        let frequency = 1.0 / period_sec;
                        let km_per_hr = 0.517 * frequency + 0.353;
                        // TODO round to like 1 or 2 decimal places and only emit the event when it actually changes.
                        //event_tx.send(Event::SpeedChanged(km_per_hr));
                    }
                    speed_pin_level = current_speed_pin_level;
                }

                thread::sleep(Duration::from_millis(10));
            }
        });
        // if let Err(_err) = t.join() {
        //     // logfile?
        // };
    }

    /**
     * Blocks waiting for commands.
     */
    pub fn run(self: &mut Self) {

        self.watch_inputs();

        for command in self.command_rx.iter() {
            let result = match command {
                Command::SetSpeed(desired_speed) => {
                    self.set_speed(desired_speed);
                },
                Command::Raise => {
                    // TODO check current incline, don't go too high
                    self.event_tx.send(Event::Msg(String::from("raising incline...")));
                    self.pins.incline_up_pin.toggle();
                    thread::sleep(Duration::from_millis(5000));
                    self.pins.incline_up_pin.toggle();
                    self.event_tx.send(Event::Msg(String::from("Done raising incline.")));
                },
                Command::Lower => {
                    // TODO check current incline, don't go too low
                    self.pins.incline_down_pin.toggle();
                    thread::sleep(Duration::from_millis(5000));
                    self.pins.incline_down_pin.toggle();
                },
                Command::Shutdown => {
                    break;
                }
            };
        }
    }

    fn start(self: &Self) {
        if let Ok(true) = self.pins.pwm.is_enabled() {
            return;
        }

        self.pins.pwm.enable()
            .and_then(|()| self.pins.pwm.set_period(PWM_PERIOD))
            .map_err(|err| TreadmillError::GenericError(err.to_string()))
            ;
    }

    fn set_speed(self: &Self, speed: f32) {
        self.log(&format!("set speed command received, desired speed: {}", speed));
        if speed > 0.0 {
            if let Ok(false) = self.pins.pwm.is_enabled() {
                self.start();
            }
        } else {
            if let Ok(true) = self.pins.pwm.is_enabled() {
                self.stop();
                return;
            }
        }

        let duty_cycle = PiTreadmill::km_per_hour_to_duty_cycle(speed);
        self.log(&format!("setting duty cycle to {}", duty_cycle));

        self.pins.pwm.enable()
            .and_then(|()| self.pins.pwm.set_duty_cycle(duty_cycle))
            .map_err(|err| TreadmillError::GenericError(err.to_string()))
            .or_else(|err| self.event_tx.send(Event::Msg(err.to_string())))
            ;
        let r = self.event_tx.send(
            Event::Msg(format!("PWM Polarity: {:?}, period: {:?}, duty: {:?}",
                               self.pins.pwm.polarity(),
                               self.pins.pwm.period(),
                               self.pins.pwm.duty_cycle())));
    }

    fn stop(self: &Self) {
        self.log("received stop command");
        if let Ok(false) = self.pins.pwm.is_enabled() {
            self.log("pwm already disabled");
            return
        }

        let r = self.pins.pwm.set_duty_cycle(0.0)
            .and_then(|()| self.pins.pwm.disable());
        self.event_tx.send(Event::SpeedChanged(0.0));
    }

    pub fn km_per_hour_to_duty_cycle(kph: f32) -> f64 {
        // From measurements using the stock console:
        // 𝐷 = 3.42𝑆 + 18.6
        if kph <= 0.0 {
            0.0
        } else {
            1.0f64.max(3.42f64 * f64::from(kph) + 18.6f64) / 100f64
        }
    }

    fn log(self: &Self, msg: &str) {
        self.event_tx.send(Event::Msg(msg.to_string()));
    }
}

