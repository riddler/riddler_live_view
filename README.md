# RiddlerLiveView

RiddlerLiveView renders what [Riddler](https://hex.pm/packages/riddler)
presents as Phoenix LiveView. Riddler answers what one visitor sees at one
step of a Journey; this package turns that answer into plain semantic HTML: a
function component for each element kind and one LiveComponent a host embeds.

## Why RiddlerLiveView

A host that presents a Journey in LiveView would otherwise write the same
markup for every question, button and message, and keep it in step with
Riddler's vocabulary by hand. Putting that markup in one package keeps a
patron-registration screen looking the same wherever it is embedded, and keeps
the host to what is its own: who may see a Journey, where it runs and what
happens when a visitor submits.

This version is unreleased. It carries the screen's frame, a component for
each element kind riddler presents - heading, text, text question, secret
question, choice question, boolean question and button - the Back control,
findings drawn beside the questions they name, and
`RiddlerLiveView.Journey`, the LiveComponent that shows a Journey; the package
stays at 0.0.0 until its first release.

## Installation

`riddler_live_view` is not on Hex yet. Until its first release, depend on the
repository in your `mix.exs`:

```elixir
def deps do
  [
    {:riddler_live_view, github: "riddler/riddler_live_view"}
  ]
end
```

The first release is installed from Hex as `riddler_live_view`, with a
version requirement this section will then carry.

> **Pre-1.0.** The public API is still moving, and a minor version may break
> it. Once the package is on Hex, pinning to an exact minor - `~> X.Y.0` - is
> the recommended way to consume it until 1.0; until then, pin the git
> dependency with `ref:` or `tag:`.

## Basic usage

Embed a patron's registration Journey in a LiveView, naming the Journey and
the host's modules implementing `Riddler.Journey.Host` and
`Riddler.Journey.Access`:

```heex
<.live_component
  module={RiddlerLiveView.Journey}
  id="registration"
  journey={@journey}
  host={Library.RegistrationHost}
  access={Library.PatronAccess}
  actor={@patron_id}
/>
```

The component asks the host where the Journey is, draws the screen, and hands
the host each submit and back request; the host's engine steps the Journey.

The markup is plain semantic HTML with a `class` and stable `data-riddler-*`
attributes on every component; the package ships no stylesheet.

## Documentation

- Do
  - [Render a Journey in a LiveView](https://hexdocs.pm/riddler_live_view/render-a-journey.html): write the host and access modules, embed `RiddlerLiveView.Journey`, and see what the visitor is shown.
  - [Scope a Path to who may see it](https://hexdocs.pm/riddler_live_view/scope-a-path.html): start a Journey under a scope, check it against the Path's kind, and say who belongs to it.
  - [Draw an element of your own kind](https://hexdocs.pm/riddler_live_view/draw-an-element-of-your-own-kind.html): register a component for a kind the package does not draw, and see what a screen with an undrawn kind does.
  - [Offer an authored skip](https://hexdocs.pm/riddler_live_view/offer-an-authored-skip.html): author a button that leaves a screen unfinished, and let the host honour it.
- Look up
  - [`RiddlerLiveView.Journey`](https://hexdocs.pm/riddler_live_view/RiddlerLiveView.Journey.html): every assign, what is drawn, who may see a Journey, and what a submit carries.
  - [`RiddlerLiveView.Components`](https://hexdocs.pm/riddler_live_view/RiddlerLiveView.Components.html): the frame, each element's component, the findings and the `data-riddler-*` attributes.
  - [The changelog](https://hexdocs.pm/riddler_live_view/changelog.html): what changed in each version.
  - [Riddler](https://hexdocs.pm/riddler): the package whose answers this one renders.
- Understand
  - [The decision record](https://github.com/riddler/riddler_live_view/blob/main/docs/adr/0001-what-the-package-is.md): why the package renders what riddler presents, owns no state and steps nothing.

## Compatibility

RiddlerLiveView needs Elixir 1.18 or later (`elixir: "~> 1.18"`). It has two
runtime dependencies: [riddler](https://hex.pm/packages/riddler) `~> 0.8`,
which presents each step of a Journey, and
[phoenix_live_view](https://hex.pm/packages/phoenix_live_view) `~> 1.2`,
which renders it. Nothing in the statifier family is a dependency: a host
wires its execution engine to this package, never the reverse.

## License

MIT. See [LICENSE](https://github.com/riddler/riddler_live_view/blob/main/LICENSE).
