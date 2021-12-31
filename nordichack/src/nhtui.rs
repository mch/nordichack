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
use tui::widgets::{Widget, Block, Borders, Paragraph, Wrap, List, ListItem};
use tui::text::{Text};
use crate::treadmill::{Event, Command};
use crate::treadmill;

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
    let mut events: Vec<String> = Vec::new();
    let mut counter = 0;
    let mut speed: f32 = 0.0;
    let mut incline: f32 = 0.0;

    // UI Loop
    loop {
        // View
        let event_log_items: Vec<ListItem> = events.iter().rev()
          .map(|item| ListItem::new(Text::from(item.clone()))).collect();

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

            let event_log = List::new(event_log_items)
                .block(Block::default().title("Treadmill Events").borders(Borders::ALL))
                .style(Style::default().fg(Color::White))
                //.highlight_style(Style::default().add_modifier(Modifier::ITALIC))
            //.highlight_symbol(">>")
                ;

            let chunks = Layout::default()
                .direction(Direction::Horizontal)
                .constraints([Constraint::Percentage(50), Constraint::Percentage(50)].as_ref())
                .split(f.size());

            f.render_widget(info, chunks[0]);
            f.render_widget(event_log, chunks[1]);
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
                                speed += treadmill::DEFAULT_KM_PER_HOUR_INCREMENT;
                                tx.send(Command::SetSpeed(speed));
                            },
                            Key::Down => {
                                message = String::from("Slowing down...");
                                speed -= treadmill::DEFAULT_KM_PER_HOUR_INCREMENT;
                                tx.send(Command::SetSpeed(speed));
                            },
                            Key::Right => {
                                message = String::from("Steeper!");
                                tx.send(Command::Raise);
                            }
                            Key::Left => {
                                message = String::from("Not... so... steep.");
                                tx.send(Command::Lower);
                            },
                            Key::Char('1') => {
                                speed = 2.0;
                                tx.send(Command::SetSpeed(speed));
                            },
                            Key::Char('2') => {
                                speed = 4.0;
                                tx.send(Command::SetSpeed(speed));
                            },
                            Key::Char('3') => {
                                speed = 6.0;
                                tx.send(Command::SetSpeed(speed));
                            },
                            Key::Char('4') => {
                                speed = 8.0;
                                tx.send(Command::SetSpeed(speed));
                            },
                            Key::Char('5') => {
                                speed = 10.0;
                                tx.send(Command::SetSpeed(speed));
                            },
                            Key::Char('6') => {
                                speed = 12.0;
                                tx.send(Command::SetSpeed(speed));
                            },
                            Key::Char('7') => {
                                speed = 14.0;
                                tx.send(Command::SetSpeed(speed));
                            },
                            Key::Char('8') => {
                                speed = 16.0;
                                tx.send(Command::SetSpeed(speed));
                            },
                            Key::Char('9') => {
                                speed = 18.0;
                                tx.send(Command::SetSpeed(speed));
                            },
                            // etc
                            Key::Char(' ') => {
                                if speed == 0.0 {
                                    speed = treadmill::DEFAULT_KM_PER_HOUR;
                                    tx.send(Command::SetSpeed(speed));
                                    message = String::from("Start");
                                } else {
                                    speed = 0.0;
                                    tx.send(Command::SetSpeed(speed));
                                    message = String::from("Stop");
                                }
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
                            Event::SpeedChanged(speed) => {
                                message = format!("Speed is now {}", speed);
                                events.push(message.clone());
                            },
                            Event::InclineSet(speed) => {
                                message = format!("Incline is now {}", speed);
                                events.push(message.clone());
                            },
                            Event::KeyRemoved => {
                                message = String::from("Safety Key removed!");
                                events.push(message.clone());
                            },
                            Event::KeyInserted => {
                                message = String::from("Safety Key inserted!");
                                events.push(message.clone());
                            }
                            Event::Msg(msg) => {
                                message = msg;
                                events.push(message.clone());
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
