# waybright
---

A dart library for building wayland compositors using wlroots, along with a
sample compositor located in `/bin`.

I don't understand everything going on in this whole wayland environment (though I am trying).
And i've never made a window manager. And I lowkey don't know what I'm doing.

But kinda tired of reading. Now, me just do. **YOLO**.

<!--
A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.
-->

## Requirements
- wayland (I'm using *v1.21.0*)
- wayland-protocols (I'm using *v1.27*)
- wlroots (I'm using *v0.15.1*)
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
