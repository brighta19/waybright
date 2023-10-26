# waybright

*Waybright* is a work-in-progress dart library utilizing wlroots for building
wayland compositors.\
Only for Linux (and probably WSL).

**Use this library if you dare. 🙃**

---

## Dependencies
- wayland (v1.21.93)
- wayland-protocols (v1.27)
- wlroots (v0.16.2)
- make

The `Dockerfile` located in `.devcontainer/` can be used as a reference for
 getting everything to work.

## Using waybright

### `pubspec.yaml`

There may be breaking changes, so it's recommended to reference a specific
commit SHA when adding this dependency to your project's `pubspec.yaml`.

Example:
```yaml
# ...
dependencies:
  waybright:
    git:
      url: https://github.com/brighta19/waybright.git
      ref: <commit SHA>
# ...
```

### `waybright.so`

The current working directory of a running dart program must also contain
`waybright.so`, a custom shared library. Whatever directory you run a dart
project must also have `waybright.so` This may or may not be the root directory
of the dart project. [See the example.](#running-the-example) \
To create it,
simply run in the root directory:

```console
> make
```

Then move or copy `build/waybright.so` into your own project.

## Running the example

Building `waybright.so` also produces a copy in `/example`, so simply run the
`main.dart` program:

```console
> cd example
> dart run main.dart
```

## Documentation

Generate the (very little) documentation using this command:

```sh
dart doc
```
