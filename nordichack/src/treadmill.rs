use std::sync::mpsc::{channel, Sender, Receiver};

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
 * Treadmill message dispatcher, responsible for cross thread communication. Receives commands and
 * sends events to/from other threads.
 */
pub struct TreadmillDispatcher<T> {
    treadmill: T,
    tx: Sender<Event>,
    rx: Receiver<Command>,
}

impl<T> TreadmillDispatcher<T> {
    pub fn new(treadmill: T, tx: Sender<Event>, rx: Receiver<Command>) -> TreadmillDispatcher<T>
    where T: Treadmill {
        TreadmillDispatcher {
            treadmill,
            tx,
            rx
        }
    }
}

/**
 * Treadmill trait
 */
pub trait Treadmill {
    // fn start();
    // fn stop();
    // fn set_speed(speed: f32);
    // fn speed_up();
    // fn slow_down();
    // fn raise();
    // fn lower();
}
