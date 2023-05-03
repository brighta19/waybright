# waybright

A dart library for building wayland compositors using wlroots, along with a
sample compositor located in `/bin`.

**WARNING: I have no idea what I'm doing. Use this library if you dare.**

---

I got interested in the concept of making my own window manager. Wayland is apparently the new fresh shoes compared to the old X11.

This is my first venture in wayland. and x11. and (kinda) custom desktop environments. and building (public) libraries. etc.

But I'm bored of reading and trying to understand.
Now, me just code. Don't expect perfectness.

**YOLO**.

---

How did i come up with `waybright`? I took wayland, I took my name (Bright) and I *performed intense fusion*.

And I like it. 🙂

---

## Requirements
- wayland (I'm using *v1.21.0*)
- wayland-protocols (I'm using *v1.27*)
- wlroots (I'm using *v0.16.2*)
- whatever those three libraries require
- make
- dart

## Building
```sh
make
```

## Running
```sh
./build/waybright
```

## Documentation
Generate using this command:
```sh
dart doc
```

## Development
Helpful commands:
```sh
make build-deps # to compile src/wayland.c and build the dart bindings
dart run # to compile and execute temporarily in one command
```
