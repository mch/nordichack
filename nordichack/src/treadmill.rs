use std::sync::mpsc::{channel, Sender, Receiver};
use std::thread::{sleep};
use std::time::{Duration};

/**
 * Default speed if the start button is pressed.
 */
pub const DEFAULT_KM_PER_HOUR: f64 = 2.0;

/**
 * How much the speed should change when the ± buttons are pressed.
 */
pub const DEFAULT_KM_PER_HOUR_INCREMENT: f64 = 0.5;

/**
 * Sent from the UI to the treadmill.
 */
pub enum Command {
    Start,
    Stop,
    SetSpeed(f32),
    SpeedUp,
    SlowDown,
    Raise,
    Lower,
    Shutdown, // Stop the treadmill and exit the thread
}

/**
 * Received by the UI from the treadmill.
 */
pub enum Event {
    SpeedSet(f32),
    InclineSet(f32),
    KeyRemoved,
    KeyInserted,
    Msg(String),
}

/**
 * Fake treadmill for testing the UI
 */
pub struct FakeTreadmill {
    command_rx: Receiver<Command>,
    event_tx: Sender<Event>,
    speed: f32,
    incline: f32,
}

const DEFAULT_SPEED: f32 = 2.0;

impl FakeTreadmill {

    pub fn new(command_rx: Receiver<Command>, event_tx: Sender<Event>) -> Result<FakeTreadmill, String> {
        Ok(FakeTreadmill { command_rx, event_tx, speed: 0.0, incline: 0.0 })
    }

    /**
     * Blocks waiting for commands.
     */
    pub fn run(self: &mut Self) {
        for command in self.command_rx.iter() {
            match command {
                Command::Start => {
                    self.speed = DEFAULT_SPEED;
                    sleep(Duration::from_millis(100));
                    self.event_tx.send(Event::SpeedSet(self.speed));
                },
                Command::Stop => {
                    self.speed = 0.0;
                    sleep(Duration::from_millis(100));
                    self.event_tx.send(Event::SpeedSet(self.speed));
                },
                Command::SetSpeed(desiredSpeed) => {
                    self.speed = desiredSpeed;
                    sleep(Duration::from_millis(100));
                    self.event_tx.send(Event::SpeedSet(self.speed));
                },
                Command::SpeedUp => {
                    self.speed += 1.0;
                    sleep(Duration::from_millis(100));
                    self.event_tx.send(Event::SpeedSet(self.speed));
                },
                Command::SlowDown => {
                    if self.speed > 0.0 {
                        self.speed -= 1.0;
                        if self.speed < 0.0 { self.speed = 0.0 };
                        sleep(Duration::from_millis(100));
                        self.event_tx.send(Event::SpeedSet(self.speed));
                    }
                },
                Command::Raise => {
                    self.incline += 1.0;
                    sleep(Duration::from_millis(100));
                    self.event_tx.send(Event::InclineSet(self.incline));
                },
                Command::Lower => {
                    if self.incline > 0.0 {
                        self.incline -= 1.0;
                        if self.incline < 0.0 { self.incline = 0.0; };
                        sleep(Duration::from_millis(100));
                        self.event_tx.send(Event::InclineSet(self.incline));
                    }
                },
                Command::Shutdown => {
                    self.speed = 0.0;
                    sleep(Duration::from_millis(100));
                    self.event_tx.send(Event::SpeedSet(self.speed));
                    break;
                }
            }
        }
    }
}
