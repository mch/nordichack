use rppal::gpio::{self, Gpio, IoPin, Level, Mode, InputPin, OutputPin};
use rppal::pwm::{self, Pwm, Channel, Polarity};
use std::time;
use std::thread;

mod nhtui;

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
            }
        }
    }
}

fn main() {
    println!("Hello, world!");

    // Start a separate thread for handling GPIO inputs?
    // And a separate one for outputs?
    // Run UI on main thread or separate thread?
    let ui_thread = thread::spawn(|| {
        nhtui::tui();
    });

    let pins = set_up_pins();
    match pins {
        Ok(_) => {
            // do stuff
            // poll for interrupts on input pins, or use async interrupts
            // drive outputs based on user inputs
            println!("Treadmill IO set up successful!");
        },
        Err(err) => {
            //println!("Failed to set up treadmill: {}", err);
        }
    }

    ui_thread.join();
}

fn set_up_pins() -> Result<TreadmillPins, TreadmillError> {
    // Inputs are pulled high by default, and the motor controller pulls them low to generate a
    // signal. Outputs are low by default, setting them high causes stuff to happen.
    let speed_sensor_pin = Gpio::new()?.get(GREEN_SPEED_SENSOR_GPIO_PIN)?.into_input_pullup();

    // PWM to drive the treadmill
    let pwm = Pwm::new(Channel::Pwm0)?;
    pwm.set_polarity(Polarity::Normal)?;

    let incline_up_pin = Gpio::new()?.get(ORANGE_INCLINE_UP_GPIO_PIN)?.into_output_low();
    let incline_down_pin = Gpio::new()?.get(YELLOW_INCLINE_DOWN_GPIO_PIN)?.into_output_low();
    let incline_sensor_pin = Gpio::new()?.get(VIOLET_INCLINE_SENSOR_GPIO_PIN)?.into_input_pullup();

    // When the key is inserted, the safety pin will be pulled low.
    // When the key is removed, it will float, so we want to pull high here.
    let safety_pin = Gpio::new()?.get(SAFETY_SWITCH_GPIO_PIN)?.into_input_pullup();

    Ok(TreadmillPins {
        speed_sensor_pin, pwm, incline_up_pin, incline_down_pin, incline_sensor_pin, safety_pin,
    })
}
