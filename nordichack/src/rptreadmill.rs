use crossbeam_channel::{unbounded, Sender, Receiver, Select};
use rppal::gpio::{self, Gpio, InputPin, OutputPin, Trigger, Level};
use rppal::pwm::{self, Pwm, Channel};
use std::thread;
use std::time::{Duration, Instant};
use crate::treadmill::{Command, Event};

const GREEN_SPEED_SENSOR_GPIO_PIN: u8 = 17;
const BLUE_PWM_GPIO_PIN: u8 = 18;
const ORANGE_INCLINE_UP_GPIO_PIN: u8 = 27;
const YELLOW_INCLINE_DOWN_GPIO_PIN: u8 = 22;
const VIOLET_INCLINE_SENSOR_GPIO_PIN: u8 = 23;
const SAFETY_SWITCH_GPIO_PIN: u8 = 24;

const PWM_PERIOD: Duration = Duration::from_millis(50);

const SPEED_PIN_DEBOUNCE_MS: u128 = 15u128;
const INCLINE_PIN_DEBOUNCE_MS: u128 = 100u128;
const SAFETY_PIN_DEBOUNCE_MS: u128 = 50u128;

struct OutputPins {
    pwm: Pwm,
    incline_up_pin: OutputPin,
    incline_down_pin: OutputPin,
}

struct InputPins {
    speed_sensor_pin: InputPin,
    incline_sensor_pin: InputPin,
    safety_pin: InputPin,
}

enum InputEvent {
    Speed(u128),
    Incline(u128),
    SafetyKeyRemoved,
    SafetyKeyInserted,
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

pub struct PiTreadmill {
    pins: OutputPins,
    command_rx: Receiver<Command>,
    event_tx: Sender<Event>,
    running: bool,
    current_speed: f32,
    speeds: [f32; 10],
    speeds_index: usize,
}

impl PiTreadmill {
    #[allow(dead_code)]
    pub fn new(command_rx: Receiver<Command>, event_tx: Sender<Event>) -> Result<PiTreadmill, String> {
        let pins = PiTreadmill::set_up_output_pins();
        pins.map(|pins| PiTreadmill { pins, command_rx, event_tx, running: true, current_speed: 0.0, speeds: [0.0; 10], speeds_index: 0 })
            .map_err(|err| err.to_string())
    }

    /**
     * Blocks waiting for commands.
     */
    #[allow(dead_code)]
    pub fn run(self: &mut Self) {
        let (input_tx, input_rx) = unbounded::<InputEvent>();
        let input_handler = PollingInputPinHandler::new(&input_tx);
        //let input_handler = InterruptInputPinHandler::new(&input_tx);
        input_handler.map(|handler| handler.watch_inputs())
            .map_err(|err| {
                self.event_tx.send(Event::Msg(format!("Failed to set up input: {}", err))).ok();
            }).ok();

        let mut select = Select::new();
        // To avoid borrowing self as both mutable and immutable, clone the stored command_rx
        let command_rx = self.command_rx.clone();
        let command_op = select.recv(&command_rx);
        let input_op = select.recv(&input_rx);

        while self.running {
            let op = select.select();
            if command_op == op.index() {
                let command = op.recv(&command_rx);
                if let Ok(command) = command {
                    self.handle_command(&command);
                };
            } else if input_op == op.index() {
                let event = op.recv(&input_rx);
                if let Ok(event) = event {
                    self.handle_input_event(&event);
                };
            }
        }
    }

    fn set_up_output_pins() -> Result<OutputPins, TreadmillError> {
        // PWM to drive the treadmill
        let pwm = Pwm::new(Channel::Pwm0)?;
        pwm.disable();
        pwm.set_period(PWM_PERIOD);
        pwm.set_pulse_width(Duration::from_millis(50));
        // This line is causing a OS error 22:
        // pwm.set_polarity(Polarity::Normal)?;

        let incline_up_pin = Gpio::new()?.get(ORANGE_INCLINE_UP_GPIO_PIN)?.into_output_low();
        let incline_down_pin = Gpio::new()?.get(YELLOW_INCLINE_DOWN_GPIO_PIN)?.into_output_low();

        Ok(OutputPins {
            pwm, incline_up_pin, incline_down_pin
        })
    }

    fn handle_command(self: &mut Self, command: &Command) {
        match command {
            Command::SetSpeed(desired_speed) => {
                self.set_speed(*desired_speed);
            },
            Command::Raise => {
                // TODO check current incline, don't go too high
                self.event_tx.send(Event::Msg(String::from("raising incline...")));
                self.pins.incline_up_pin.toggle();
                // TODO change this to something that doesn't block, and probably that
                // responds to InputEvent::Incline() or a timeout
                thread::sleep(Duration::from_millis(5000));
                self.pins.incline_up_pin.toggle();
                self.event_tx.send(Event::Msg(String::from("Done raising incline.")));
            },
            Command::Lower => {
                // TODO check current incline, don't go too low
                self.pins.incline_down_pin.toggle();
                // TODO change this to something that doesn't block, and probably that
                // responds to InputEvent::Incline() or a timeout
                thread::sleep(Duration::from_millis(5000));
                self.pins.incline_down_pin.toggle();
            },
            Command::Shutdown => {
                self.running = false;
            }
        }
    }

    fn handle_input_event(self: &mut Self, event: &InputEvent) {
        match event {
            &InputEvent::Incline(period) => {
                // If incline is supposed to be changing and it is not, STOP and inform user.
                self.event_tx.send(Event::Msg(format!("Incline changed, period: {}", period)));
            },
            &InputEvent::Speed(period) => {
                // If speed is not > 0 and it is supposed to be, STOP and inform user.
                let period_sec = period as f32 / 1000f32;
                let frequency = 1.0 / period_sec;
                let km_per_hr = 0.517 * frequency + 0.353;

                self.speeds[self.speeds_index] = km_per_hr;
                self.speeds_index = (self.speeds_index + 1) % self.speeds.len();
                let avg_speed: f32 = self.speeds.iter().sum::<f32>() / (self.speeds.len() as f32);
                let current_speed = (avg_speed * 100.0).round() / 100.0;
                if self.current_speed != current_speed {
                    self.current_speed = current_speed;
                    self.event_tx.send(Event::SpeedChanged(current_speed));
                }
            },
            &InputEvent::SafetyKeyInserted => {
                self.event_tx.send(Event::KeyInserted);
            },
            &InputEvent::SafetyKeyRemoved => {
                //self.stop(); // TODO Add RC filter circuit

                self.event_tx.send(Event::KeyRemoved);
            }
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

trait InputPinHandler {
    fn watch_inputs(self: &Self);
}

struct InterruptInputPinHandler;

impl InterruptInputPinHandler {
    fn new(event_tx: &Sender<InputEvent>) -> Result<InterruptInputPinHandler, TreadmillError> {
        // Inputs to the Pi are pulled high by default, and the motor controller pulls them low to
        // generate a signal.
        let mut speed_sensor_pin = Gpio::new()?.get(GREEN_SPEED_SENSOR_GPIO_PIN)?.into_input_pullup();
        let speed_event_tx = event_tx.clone();
        let mut speed_pin_transition_instant = Instant::now();
        speed_sensor_pin.set_async_interrupt(Trigger::FallingEdge, move |_level| {
            let current_instant = Instant::now();
            let period_ms = speed_pin_transition_instant.elapsed().as_millis();
            // T at 11 mph is about 30ms, so wait at least 15ms since last trigger for debouncing.
            if period_ms > SPEED_PIN_DEBOUNCE_MS {
                speed_pin_transition_instant = current_instant;
                speed_event_tx.send(InputEvent::Speed(period_ms));
            }
        });

        let mut incline_sensor_pin = Gpio::new()?.get(VIOLET_INCLINE_SENSOR_GPIO_PIN)?.into_input_pulldown();
        let incline_event_tx = event_tx.clone();
        let mut incline_transition_instant = Instant::now();
        incline_sensor_pin.set_async_interrupt(Trigger::FallingEdge, move |_level| {
            let current_instant = Instant::now();
            let period_ms = incline_transition_instant.elapsed().as_millis();
            // This signal should transition about once a second. It is high for about 800ms, then
            // drops low for 200ms.
            if period_ms > INCLINE_PIN_DEBOUNCE_MS {
                incline_transition_instant = current_instant;
                incline_event_tx.send(InputEvent::Incline(period_ms));
            }
        });

        // When the key is inserted, the safety switch closes to ground, and must be pulled high
        // otherwise.
        let mut safety_pin = Gpio::new()?.get(SAFETY_SWITCH_GPIO_PIN)?.into_input_pullup();
        let safety_event_tx = event_tx.clone();
        safety_pin.set_async_interrupt(Trigger::Both, move |level| {
            if level == Level::High {
                safety_event_tx.send(InputEvent::SafetyKeyRemoved);
            } else {
                safety_event_tx.send(InputEvent::SafetyKeyInserted);
            }
        });

        Ok(InterruptInputPinHandler)
    }
}

impl InputPinHandler for InterruptInputPinHandler {

    fn watch_inputs(self: &Self) {
    }
}

struct PollingInputPinHandler {
    event_tx: Sender<InputEvent>,
}

impl PollingInputPinHandler {
    fn new(event_tx: &Sender<InputEvent>) -> Result<PollingInputPinHandler, TreadmillError> {
        Ok(PollingInputPinHandler { event_tx: event_tx.clone() })
    }
}

impl InputPinHandler for PollingInputPinHandler {
    fn watch_inputs(self: &Self) {
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

            // Are there better ways to handle multiple values in Results? Nested .map's?
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
                        event_tx.send(InputEvent::SafetyKeyRemoved)
                    } else {
                        event_tx.send(InputEvent::SafetyKeyInserted)
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
                        if period_ms > 15u128 {
                            speed_pin_transition_high_instant = current_speed_pin_read_instant;
                            event_tx.send(InputEvent::Speed(period_ms));
                        }
                    }
                    speed_pin_level = current_speed_pin_level;
                }

                // TODO read incline pin

                thread::sleep(Duration::from_millis(10));
            }
        });
        // if let Err(_err) = t.join() {
        //     // logfile?
        // };
    }
}
