use std::thread;
use crossbeam_channel::{unbounded, Sender, Receiver};
use simplelog::*;
use log::*;
use std::fs::File;

mod nhtui;
mod treadmill;
mod rptreadmill;

use crate::rptreadmill::PiTreadmill;
use crate::treadmill::FakeTreadmill;

fn main() {
    CombinedLogger::init(vec![WriteLogger::new(LevelFilter::Debug, Config::default(), File::create("nordichack.log").unwrap())]);

    let (event_tx, event_rx): (Sender<treadmill::Event>, Receiver<treadmill::Event>) = unbounded::<treadmill::Event>();
    let (command_tx, command_rx): (Sender<treadmill::Command>, Receiver<treadmill::Command>) = unbounded::<treadmill::Command>();

    debug!("Starting UI thread...");
    let ui_thread = thread::spawn(move || {
        if let Err(err) = nhtui::tui(command_tx, event_rx) {
            println!("Failed to start UI thread: {}", err);
        };
    });

    debug!("Starting treadmill...");
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

    debug!("Waiting for UI thread to exit...");
    if let Err(err) = ui_thread.join() {
        println!("Failed to join UI thread: {:?}", err);
    }

    debug!("All done.");
}

