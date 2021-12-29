use std::io::{Write, stdout, stdin};
use std::io;
use std::sync::mpsc::{Sender, Receiver, channel};
use std::thread;
use std::time::Duration;
use termion::event::Key;
use termion::input::TermRead;
use termion::raw::IntoRawMode;
use termion::{async_stdin};
use tui::Terminal;
use tui::backend::TermionBackend;
use tui::layout::{Layout, Constraint, Direction, Alignment};
use tui::style::{Style, Color};
use tui::widgets::{Widget, Block, Borders, Paragraph, Wrap};
use crate::treadmill::{Event, Command};

enum UiEvent {
    UiKey(Key),
    UiTreadmill(Event),
}

pub fn tui(tx: Sender<Command>, rx: Receiver<Event>) -> Result<(), io::Error> {
    let (key_tx, key_rx) = channel::<Key>();
    let input_thread = thread::spawn(move || {
        let stdin = stdin();
        let mut keys = stdin.keys();
        for key in keys {
            match key {
                Ok(key) => {
                    key_tx.send(key).unwrap();
                },
                Err(err) => {
                    // idk
                }
            }
        }
    });

    // Idk, might work for now.
    // Using tokio for async might be better.
    let (event_tx, event_rx) = channel::<UiEvent>();
    let merge_thread = thread::spawn(move || {
        let duration = Duration::from_millis(10);
        loop {
            let key_event = key_rx.recv_timeout(duration);
            if key_event.is_ok() {
                event_tx.send(UiEvent::UiKey(key_event.unwrap()));
            }
            let treadmill_event = rx.recv_timeout(duration);
            if treadmill_event.is_ok() {
                event_tx.send(UiEvent::UiTreadmill(treadmill_event.unwrap()));
            }
        }
    });

    let stdout = io::stdout().into_raw_mode()?;
    let backend = TermionBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;
    terminal.clear()?;

    // View Model
    let mut message: String = String::from("Hello NordicHack!");
    let mut counter = 0;
    let mut speed: f32 = 0.0;
    let mut incline: f32 = 0.0;

    // UI Loop
    loop {
        // View
        terminal.draw(|f| {
            let size = f.size();
            let block = Block::default()
                .title("NordicHack")
                .borders(Borders::ALL);
            let info = Paragraph::new(format!("{}, {}", message, counter))
                .block(block)
                .style(Style::default().fg(Color::White).bg(Color::Black))
                .alignment(Alignment::Center)
                .wrap(Wrap { trim: true });

            f.render_widget(info, size);
        })?;
        counter += 1;

        // Update
        let event = event_rx.recv();
        match event {
            Ok(event) => {
                match event {
                    UiEvent::UiKey(key) => {
                        match key {
                            Key::Up => {
                                message = String::from("Going Faster!");
                                tx.send(Command::SpeedUp);
                            },
                            Key::Down => {
                                message = String::from("Slowing down...");
                                tx.send(Command::SlowDown);
                            },
                            Key::PageUp => {
                                message = String::from("Steeper!");
                                tx.send(Command::Raise);
                            }
                            Key::PageDown => {
                                message = String::from("Not... so... steep.");
                                tx.send(Command::Lower);
                            },
                            Key::Char('1') => {
                                tx.send(Command::SetSpeed(1.0));
                            },
                            Key::Char('2') => {
                                tx.send(Command::SetSpeed(2.0));
                            },
                            Key::Char('3') => {
                                tx.send(Command::SetSpeed(3.0));
                            },
                            // etc
                            Key::Char(' ') => {
                                message = String::from("Emergency Stop!");
                            },
                            Key::Esc => {
                                break;
                            },
                            Key::Char('q') => {
                                break;
                            },
                            _ => {}
                        }

                    },
                    UiEvent::UiTreadmill(event) => {
                        match event {
                            Event::SpeedSet(speed) => {
                                message = format!("Speed is now {}", speed);
                            },
                            Event::InclineSet(speed) => {
                                message = format!("Incline is now {}", speed);
                            },
                            Event::KeyRemoved => {
                                message = String::from("Safety Key removed!");
                            },
                            Event::KeyInserted => {
                                message = String::from("Safety Key inserted!");
                            }
                            Event::Msg(msg) => {
                                message = msg;
                            }
                        }
                    }
                }
            },
            Err(err) => {
                message = format!("err: {}", err);
            }
        };
    }

    tx.send(Command::Shutdown);
    terminal.clear()?;

    Ok(())
}
