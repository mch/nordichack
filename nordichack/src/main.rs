use std::thread;
use std::sync::mpsc::channel;

mod nhtui;
mod treadmill;
mod rptreadmill;

use crate::rptreadmill::PiTreadmill;
use crate::treadmill::FakeTreadmill;

fn main() {
    println!("Hello, world!");

    let (event_tx, event_rx) = channel::<treadmill::Event>();
    let (command_tx, command_rx) = channel::<treadmill::Command>();

    // Start a separate thread for handling GPIO inputs?
    // And a separate one for outputs?
    // Run UI on main thread or separate thread?
    let ui_thread = thread::spawn(move || {
        nhtui::tui(command_tx, event_rx);
    });

    #[cfg(all(feature = "real_treadmill", feature = "fake_treadmill"))]
    compile_error!("Only one of real_treadmill and fake_treadmill may be used.");

    #[cfg(feature = "real_treadmill")]
    let mut treadmill = PiTreadmill::new(command_rx, event_tx.clone());

    #[cfg(feature = "fake_treadmill")]
    let treadmill = FakeTreadmill::new(command_rx, event_tx.clone());

    match treadmill {
        Ok(_) => {
            // do stuff
            // poll for interrupts on input pins, or use async interrupts
            // drive outputs based on user inputs
            event_tx.send(treadmill::Event::Msg(String::from("Treadmill IO set up successful!")));
            if treadmill.is_ok() {
                treadmill.unwrap().run();
            }
        },
        Err(err) => {
            event_tx.send(treadmill::Event::Msg(format!("Failed to set up treadmill: {}", err)));
        }
    }

    ui_thread.join();
}

