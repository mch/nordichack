
use gtk::prelude::*;
use gtk::{Application, ApplicationWindow, Button, Builder};

fn main() {
    let application = Application::builder()
        .application_id("com.example.FirstGtkApp")
        .build();

    application.connect_activate(build_ui);

    application.run();
}

fn build_ui(app: &Application) {
    let builder = Builder::from_string(include_str!("ui.glade"));

    let window: ApplicationWindow = builder
        .object("window")
        .expect("Couldn't get object 'window' from builder.");
    let button: Button = builder
        .object("start")
        .expect("Couldn't get object 'start' from builder.");

    window.set_application(Some(app));

    button.connect_clicked(|_| {
        eprintln!("Start Treadmill!");
    });

    window.show_all();

}
