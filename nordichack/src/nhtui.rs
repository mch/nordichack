use std::io::{Write, stdout, stdin};
use std::io;
use termion::event::Key;
use termion::input::TermRead;
use termion::raw::IntoRawMode;
use tui::Terminal;
use tui::backend::TermionBackend;
use tui::layout::{Layout, Constraint, Direction, Alignment};
use tui::widgets::{Widget, Block, Borders, Paragraph, Wrap};
use tui::style::{Style, Color};

pub fn tui() -> Result<(), io::Error> {
    let stdin = stdin();
    let mut keys = stdin.keys();
    let stdout = io::stdout().into_raw_mode()?;
    let backend = TermionBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;
    terminal.clear();

    let mut message = "Hello NordicHack!";

    loop {
        terminal.draw(|f| {
            let size = f.size();
            let block = Block::default()
                .title("NordicHack")
                .borders(Borders::ALL);
            let info = Paragraph::new(message)
                .block(block)
                .style(Style::default().fg(Color::White).bg(Color::Black))
                .alignment(Alignment::Center)
                .wrap(Wrap { trim: true });

            f.render_widget(info, size);
        })?;

        let key = keys.next();
        match key.unwrap() {
            Ok(Key::Up) => {
                message = "Going Faster!";
            },
            Ok(Key::Down) => {
                message = "Slowing down...";
            },
            Ok(Key::PageUp) => {
                message = "Steeper!";
            }
            Ok(Key::PageDown) => {
                message = "Not... so... steep.";
            },
            Ok(Key::Char(' ')) => {
                message = "Emergency Stop!";
            }
            Ok(Key::Esc) => {
                break;
            },
            _ => {}
        }
    }

    terminal.clear();

    Ok(())
}
