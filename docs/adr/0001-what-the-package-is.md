# ADR-0001: RiddlerLiveView renders what Riddler presents, owns no state and steps nothing

Status: proposed

That the contract for who may see and step a Journey
lives in `riddler` and that this package consumes it; that a renderer asks
on mount, on every submit and on every back, with one refusal for a Journey
that does not exist and a Journey that is not the asker's; that the package
hands a host function components, one per node kind, and one LiveComponent,
`RiddlerLiveView.Journey`; that accessibility is held by a deterministic
rule suite in the ExUnit gate, seeded from axe-core; that the markup is
plain semantic HTML; that an unknown node kind follows riddler's fallback,
with a component map for a host's own kinds; and that progress is drawn
only where the host supplies it, with skip left an authored button - each
was ruled by the operator, 2026-11-23. That the runtime dependencies are
`riddler` and `phoenix_live_view` only, never a statifier package, was
ruled by the operator, 2026-11-23, with the package's name and module
namespace.

This record is written before any component it describes. The code half is
separate requests, and nothing below is citable from `lib/` until they
land, so what they add is described here, not cited. Every cite of this
repository is read at `6c2f36b`. Every cite of riddler is of the
riddler-ex repository at the tag `v0.7.0`, the commit published on Hex as
riddler 0.7.0. A cite of another repository's record carries that
repository's beads prefix, as riddler's records do: `rd-ADR-0005` is
riddler's ADR-0005,
<https://github.com/riddler/riddler-ex/blob/v0.7.0/docs/adr/0005-journey-presented-as-data.md>.

## Context

**Riddler answers what one visitor sees at one step of a Journey.**
`Riddler.Journey.present/3` answers a string-keyed map whose `"state"` is
`"screen"`, `"waiting"` or `"done"`, and for a screen, the resolved screen
of nodes and the moves the visitor has (rd-ADR-0005, Decision 3 and its
Amendment of 2026-11-18). That answer is data: riddler renders nothing,
stores nothing and steps no Journey (rd-ADR-0005, Decision 6, "What this
package does not own"). Something has to turn the answer into markup a
visitor can read and fill in, and send back what they submit.

**A host that renders it in LiveView writes the same markup every time.**
Every host that presents a patron registration in Phoenix LiveView writes
markup for each question, button and message, and keeps it in step with
riddler's vocabulary by hand. Two hosts write it twice, and differently.

**Riddler now states the contract a renderer is built to.** rd-ADR-0005's
Amendment of 2026-11-23, "who may see and step a Journey, its scope, and the
progress a host supplies", adds three modules to riddler:
`Riddler.Journey.Scope`, `Riddler.Journey.Access` with its pure
`check/4`, and `Riddler.Journey.Host`, the four callbacks a renderer drives
any host through (`lib/riddler/journey/scope.ex`,
`lib/riddler/journey/access.ex` and `lib/riddler/journey/host.ex` at
`v0.7.0`). The Amendment's Status line reads `proposed` at that tag; its
code shipped in riddler 0.7.0. It says what a renderer asks and when, and
says that riddler "renders nothing and sees no renderer, so it cannot
enforce the order". A renderer is the package that keeps it.

**The repository is a scaffold.** `lib/riddler_live_view.ex` at `6c2f36b`
holds a moduledoc and nothing else, and `mix.exs` at `6c2f36b` lists two
runtime dependencies in `deps/0`, `riddler` and `phoenix_live_view`. This
record decides what the package is before any component lands.

## Decision

### 1. The package renders a presented answer, owns no state and steps nothing

`riddler_live_view` is one hex package whose modules sit under
`RiddlerLiveView`. It renders the answer `Riddler.Journey.present/3` gives,
collects what the visitor submits and hands it to the host. It does not
start an execution, choose the next screen, store a response, keep a
Journey between visits, or decide who may see a Journey: those are the
host's, through the behaviours riddler states. What the LiveComponent holds
in its assigns is the answer it is showing and the scope it checks against,
for as long as it is mounted, and nothing it holds outlives it.

No secret value appears in the HTML a component renders, in the assigns
after a submit, or in a log line (`CLAUDE.md` at `6c2f36b`,
"Conventions").

### 2. What a host is handed

- **One function component per node kind** that a presented screen can
  carry, each rendering one node of the answer's `"nodes"`. A host may call
  them directly to lay out a screen of its own.
- **One LiveComponent, `RiddlerLiveView.Journey`**, that a host embeds to
  show a Journey's step, take what the visitor submits and give it back to
  the host. It drives the host through `Riddler.Journey.Host`'s callbacks
  and asks `Riddler.Journey.Access.check/4` before each of them, as
  Decision 3 says.

The node kinds are the ones the presented answer's schema of the required
riddler version enumerates (`priv/schemas/presented-answer.schema.json` at
`v0.7.0`; rd-ADR-0005's Amendment of 2026-11-18, "The presented answer's
schema enumerates the node types"). This record does not list them: the
components' tests enumerate them, and a kind riddler adds joins in the
release that renders it.

### 3. The Journey asks the host's access module, every time, and refuses one way

`RiddlerLiveView.Journey` refuses to mount a Journey without the host's
access module, a module implementing `Riddler.Journey.Access`. With one, it
asks `Riddler.Journey.Access.check/4` with the Journey's scope at each of
the points rd-ADR-0005's Amendment of 2026-11-23 names, under "What a
renderer asks, and when":

| When | Operation | Asked before |
|---|---|---|
| before a start, with the scope the Journey is to be started under | `:present` | `start/2` is called |
| on mount | `:present` | anything of the answer `present/1` gave is shown |
| on every submit | `:submit` | `submit/2` is called |
| on every back | `:back` | `back/2` is called |

On `{:error, :no_such_journey}` it shows one refusal, shows nothing of the
Journey, and calls no callback that would start or step it. The refusal is
the same whether the Journey does not exist or is not the actor's, and so
does not say whether the Journey exists; a host callback that answers
`{:error, :no_such_journey}` is shown the same refusal. It asks on every
submit and every back rather than once because whether an actor belongs to
a scope is the host's, and can change while a Journey is open.

### 4. An unknown node kind is not rendered and blocks the submit; a component map renders a host's own

A node whose `"type"` is not one of the kinds the package renders follows
rd-ADR-0005's fallback (its Amendment of 2026-11-18, "The fallback for a
node type a client does not know"): the component does not render that
node, and does not let the visitor submit that screen.

A host whose screens carry kinds of its own passes a component map, an
option of `RiddlerLiveView.Journey` that names, for a node type, the host's
function component that renders it. A node whose type the map names is
rendered by that component, and is a kind the LiveComponent knows, so it
does not block the submit.

### 5. Plain semantic HTML, with no styling shipped

The markup is plain semantic HTML: the element that means what the node
is, a `class` attribute on every component, and stable `data-riddler-*`
attributes a host's stylesheet and tests can select on. No CSS framework
class appears in it, and the package ships no stylesheet. How it looks is
the host's.

### 6. A deterministic accessibility rule suite runs in the gate

Accessibility is held by a rule suite of ExUnit tests over the HTML the
components render, its first rules seeded from axe-core's. It is
deterministic - the same markup always passes or fails the same rules - and
it runs in the ExUnit suite, so `mix quality` fails when a component breaks
a rule. The suite, not this record, enumerates the rules and the components
it covers.

### 7. Progress and skip

Progress is drawn only when the answer carries a `"progress"` key, which
riddler puts there only when the host supplies it (rd-ADR-0005's Amendment
of 2026-11-23, "Progress is a screen option the host supplies"). The
package counts no steps. Skip stays an authored button raising its own
outcome; the package offers no generic skip control.

### 8. The dependencies

The runtime dependencies are `riddler` and `phoenix_live_view`, and no
others. `jason` joins only if `phoenix_live_view` does not bring it and the
code needs it; in `mix.lock` at `6c2f36b`, `phoenix_live_view` lists
`jason` as optional. The package never depends on a statifier package: a
host wires its execution engine to this package through
`Riddler.Journey.Host`, not the reverse, and the day that changes is a
record before it is a dependency.

## Consequences

- A host embeds one LiveComponent and implements riddler's two behaviours,
  `Riddler.Journey.Access` and `Riddler.Journey.Host`; it writes no markup
  for the kinds the package renders.
- The package needs a riddler that carries those behaviours: 0.7.0 or
  later.
- A host's engine is invisible here. Any execution engine that can answer
  `Riddler.Journey.Host`'s four callbacks can be rendered, and none is a
  dependency.
- Every submit and every back costs one call to the host's access module
  before the host's own callback.
- A screen carrying a node the package cannot render cannot be submitted
  from it, so no visitor is moved on from a screen they saw only part of.
- A host styles the markup from its own stylesheet, selecting on the
  `class` and `data-riddler-*` attributes; it inherits no look.
- A component that fails an accessibility rule fails the gate, not a later
  audit.

## Typespecs and worked example

This record names no types: the components, their attributes and the
component map's shape are the code half's, written against the decisions
above. riddler's typespecs for the scope, the two behaviours and the
answer are in rd-ADR-0005's Amendment of 2026-11-23.

**Patron registration.** The library's host embeds `RiddlerLiveView.Journey`
on its registration page, passing its access module and its host module.
A patron signed in as `P-1001` opens their registration. On mount the
component calls the host's `present/1`, which answers the scope
`{"patron", "P-1001"}` and the details screen; it asks `check/4` with
`:present`, gets `:ok`, and renders the screen: a heading, a text question
for the reminder email, a Continue button. The patron fills it in and
presses Continue; the component asks `check/4` with `:submit`, gets `:ok`,
and calls the host's `submit/2` with what was entered. The host's engine
moves the Journey on and answers the next screen, and the component
renders it.

Another patron opens the same link. On mount `check/4` answers
`{:error, :no_such_journey}`, and the component shows the one refusal it
would show for a link to no Journey at all.

## What this does not decide

- The refusal's wording and markup, and how a missing access module is
  refused.
- How the fallback tells the visitor that a screen cannot be submitted.
- Whether the component map may replace a kind the package renders.
- How progress is drawn.
- The anonymous visitor, streaming and the transport, which rd-ADR-0005's
  Amendment of 2026-11-23 leaves open, and a repeating section.
