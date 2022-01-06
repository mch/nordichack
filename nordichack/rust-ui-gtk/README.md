# Cross Compiling GTK with Rust bindings

This is a test of cross compiling a GTK3 program for the Raspberry Pi.

There is quite a bit of set up required for this to work. You need a Raspberry Pi running the target OS because you'll need to copy files from it locally. 

0. Install the following packages on the Pi: 
```
sudo apt install -y pkg-config
```
1. Run the `setup` script to copy necessary files from the Pi. There are two things: pkg-config files, and libraries necessary for linking.
2. Start the docker container (`../scripts/run`), building the container first if necessary (`../scripts/docker-build`).
3. Run the `docker-setup` script within the container to copy files to the right place within the container.
4. Run `build`. It will probably fail, check cargo-output.txt for details.
5. If it fails, uncomment the `#linker = "mylinker"` line in .cargo/config.toml. The mylinker script adds the necessary libraries to make it work. In particular, `-lgmodule-2.0 -lX11 -lXi -lXfixes -latk-bridge-2.0 -lepoxy -lfribidi -lpangoft2-1.0 -lfontconfig -lfreetype -lXinerama -lXrandr -lXcursor -lXcomposite -lXdamage -lxkbcommon -lwayland-cursor -lwayland-egl -lwayland-client -lXext -lthai -lpixman-1 -lpng16 -lxcb-shm -lxcb -lxcb-render -lXrender -lz -lmount -latspi -lgraphite2 -luuid -lbrotlidec -ldatrie -lXau -lXdmcp -lblkid -lffi` was added in the middle of the line. I haven't been able to figure out a way of doing this properly with cargo yet.
6. Assuming it builds, copy it to the Pi and try running it.

Useful resources:
- [Cross-Compiling Rust Apps II: Linux Subtrees and Linker Shenanigans](https://capnfabs.net/posts/cross-compiling-rust-apps-linker-shenanigans-multistrap-chroot/)
- [cross](https://github.com/rust-embedded/cross) “Zero setup” cross compilation and “cross testing” of Rust crates (I didn't use this but maybe should have)
- [Cross compiling rust](https://github.com/japaric/rust-cross)
- [Autotools pkg-config cross compiling](https://autotools.info/pkgconfig/cross-compiling.html)
- [Guide to Cross Compilation for a Raspberry Pi](https://github.com/HesselM/rpicross_notes)
