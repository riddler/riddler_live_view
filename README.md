# RiddlerLiveView

RiddlerLiveView renders what [Riddler](https://hex.pm/packages/riddler)
presents as Phoenix LiveView. Riddler answers what one visitor sees at one
step of a Journey; this package turns that answer into plain semantic HTML: a
function component for each node kind and one LiveComponent a host embeds.

## Why RiddlerLiveView

A host that presents a Journey in LiveView would otherwise write the same
markup for every question, button and message, and keep it in step with
Riddler's vocabulary by hand. Putting that markup in one package keeps a
patron-registration screen looking the same wherever it is embedded, and keeps
the host to what is its own: who may see a Journey, where it runs and what
happens when a visitor submits.

This version is a scaffold. It carries no components yet, and the package
stays at 0.0.0 until its first release.

## Installation

Add `riddler_live_view` to the dependencies in your `mix.exs`:

```elixir
def deps do
  [
    {:riddler_live_view, "~> 0.0.0"}
  ]
end
```

> **Pre-1.0.** The public API is still moving, and a minor version may break
> it. Pinning to an exact minor - `~> X.Y.0` - is the recommended way to
> consume the package until 1.0.

## Basic usage

There is nothing to call yet. Fetching the package and compiling it is the
whole of what it does at this version:

```bash
mix deps.get
mix compile
```

The first release will render a patron registration screen from the answer
Riddler gives for one step of a Journey.

## Documentation

- Look up
  - [The changelog](https://hexdocs.pm/riddler_live_view/changelog.html): what changed in each version.
  - [Riddler](https://hexdocs.pm/riddler): the package whose answers this one renders.

## Compatibility

RiddlerLiveView needs Elixir 1.18 or later (`elixir: "~> 1.18"`). It has two
runtime dependencies: [riddler](https://hex.pm/packages/riddler) `~> 0.6`,
which presents each step of a Journey, and
[phoenix_live_view](https://hex.pm/packages/phoenix_live_view) `~> 1.2`,
which renders it. Nothing in the statifier family is a dependency: a host
wires its execution engine to this package, never the reverse.

## License

MIT. See [LICENSE](https://github.com/riddler/riddler_live_view/blob/main/LICENSE).
