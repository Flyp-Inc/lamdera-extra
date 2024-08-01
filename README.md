# lamdera-extra: Lamdera, with some extra stuff built right on top

This is the Flyp, Inc.-flavored implementation of the Lamdera platform.

The rationale behind this repository existing in the first place, is that we wanted a separation between our implementation of the Lamdera runtime platform, and the rest of our application.

This makes it easy for [John](https://github.com/jmpavlick) to prototype with platform-level ideas, without breaking the whole application a hundred times between iterations on some unhinged long-shot that may or may not even work out.

## What's it do, what is going on here?

- You get a fresh `Time.Posix` timestamp in-scope in `Frontend.update` and `Backend.update`
  - This makes it easy to do stuff like "put a timestamp on some value that's being persisted in the `BackendModel`
- `Lamdera.SessionId` and `Lamdera.ClientId` are wrapped in types `L.SessionId` and `L.ClientId` so that you don't mix them up and footgun yourself
- `L.SessionDict`: a dictionary that uses our `L.SessionId` type as a key
- `L.ClientSet`: a set that can contain `L.ClientId` values

## Does it even run?

Yeah, just hit `lamdera live`.

## Usage

To use `lamdera-extra` in your own Lamdera application:

### Phase 0: Install `lamdera-extra`'s dependencies
```
lamdera install elm/time
```

### Phase 1: Add it to your repo

- Submodule this repo in your project's repo
- Add the path to this repo's `lib` folder to your project's `elm.json` as a source
  - If you created a folder `vendor` for all of your submodules, and added `lamdera-extra` as a submodule, that means that you'd need to add a line to the `source-directories` field in your `elm.json` so that it looked like this when you were done:
    ```
    "source-directories": [
        "src",
        "vendor/lamdera-extra/lib"
    ],
    ```

### Phase 2: Start using it

- Replace all existing references to `import Lamdera` with `import L`
- Follow the compiler and update your types accordingly
