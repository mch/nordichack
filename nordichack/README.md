# NordicHack in Rust

Assuming the Rust tool chain is already set up for development on Ubuntu, add a few things for cross compiling: 
```
rustup target add armv7-unknown-linux-gnueabihf
sudo apt install gcc-arm-linux-gnueabihf
```

To build:
```
cargo build --release --target="armv7-unknown-linux-gnueabihf"
```

Copy to your Pi to test. 

## Pi Configuration
### Enable PWM on GPIO 18
Add `dtoverlay=pwm` to `/boot/config.txt`.
