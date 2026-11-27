# ADR-0001: RiddlerLiveView renders what Riddler presents, owns no state and steps nothing

Status: proposed

That the contract for who may see and step a Journey
lives in `riddler` and that this package consumes it; that a renderer asks
on mount, on every submit and on every back, with one refusal for a Journey
that does not exist and a Journey that is not the asker's; that the package
hands a host function components, one per element kind, and one
LiveComponent, `RiddlerLiveView.Journey`; that accessibility is held by a
deterministic rule suite in the ExUnit gate; that the markup is
plain semantic HTML; that an unknown element kind follows riddler's
fallback, with a component map for a host's own kinds; and that progress is
drawn only where the host supplies it, with skip left an authored button -
each was ruled by the operator, 2026-11-23, and so were the package's name
and module namespace. That the children of a screen are elements, as
riddler 0.8.0 names them, and that this package is written in that
spelling, was ruled by the operator, 2026-11-24. That the markup of each
element carries a `data-riddler-element` attribute and that the function
components are named per element kind was decided by the conductor under a
standing consent, 2026-11-24. The runtime dependencies are `riddler` and
`phoenix_live_view` only, never a statifier package, because a host wires
its execution engine to this package and not the reverse (`CLAUDE.md` at
`6c2f36b`, "What this project is").

This record is written before any component it describes. The code half is
separate requests, and nothing below is citable from `lib/` until they
land, so what they add is described here, not cited. Every cite of this
repository is read at `6c2f36b`. Every cite of riddler is of the
riddler-ex repository at the tag `v0.8.0`, the commit published on Hex as
riddler 0.8.0. A cite of another repository's record carries that
repository's beads prefix, as riddler's records do: `rd-ADR-0005` is
riddler's ADR-0005,
<https://github.com/riddler/riddler-ex/blob/v0.8.0/docs/adr/0005-journey-presented-as-data.md>,
and `rd-ADR-0002` is riddler's ADR-0002,
<https://github.com/riddler/riddler-ex/blob/v0.8.0/docs/adr/0002-element-document.md>.

In this record an element is always a child of a screen, as riddler's
records use the word. A piece of markup is called a tag.

## Context

**Riddler answers what one visitor sees at one step of a Journey.**
`Riddler.Journey.present/3` answers a string-keyed map whose `"state"` is
`"screen"`, `"waiting"` or `"done"`, and for a screen, the resolved screen
of elements and the moves the visitor has (rd-ADR-0005, Decision 3 and its
Amendments of 2026-11-18 and 2026-11-24). That answer is data: riddler
renders nothing, stores nothing and steps no Journey (rd-ADR-0005,
Decision 6, "What this package does not own", for storage and the stepper;
its Amendment of 2026-11-24, "What is unchanged": "Decision 6 stands: this
package renders, stores and transports nothing"). Something has to turn
the answer into markup a visitor can read and fill in, and send back what
they submit.

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
`v0.8.0`). Its code shipped in riddler 0.7.0, and its Status line reads
accepted at `v0.8.0`. It says what a renderer asks and when, and
says that riddler "renders nothing and sees no renderer, so it cannot
enforce the order". A renderer is the package that keeps it.

**Riddler 0.8.0 names a screen's children elements.** rd-ADR-0005's
Amendment of 2026-11-24, "a presented screen carries `elements`, and a
finding `element_key`", answers a presented screen's children under
`"elements"` where riddler 0.7.0 answered `"nodes"`, for a document of
either schema version, and a finding's `"element_key"` where it answered
`"node_key"`; its companion, rd-ADR-0002's Amendment of the same date, "the
children of a screen are `elements`, as `schema_version` 2", decides the
document. From those Amendments on, wherever rd-ADR-0005 and rd-ADR-0002
say node of a child of a screen, they read element (each one's Amendment
of 2026-11-24, "Which sentences this supersedes"). rd-ADR-0005's
Amendment leaves to a renderer "How a renderer draws an element, and the
attributes it marks one with"; this record decides both.

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
host's, through the behaviours riddler states. The LiveComponent holds no
response and no step beyond the answer it is showing, and nothing it holds
outlives its mount.

No secret value appears in the HTML a component renders, in the assigns
after a submit, or in a log line (`CLAUDE.md` at `6c2f36b`,
"Conventions").

### 2. What a host is handed

- **One function component per element kind** that a presented screen can
  carry, each named for the element kind it renders and rendering one
  element of the answer's `"elements"`. A host may call them directly to
  lay out a screen of its own.
- **One LiveComponent, `RiddlerLiveView.Journey`**, that a host embeds to
  show a Journey's step, take what the visitor submits and give it back to
  the host. It drives the host through `Riddler.Journey.Host`'s callbacks
  and asks `Riddler.Journey.Access.check/4` before each of them, as
  Decision 3 says.

The element kinds are the ones the presented answer's schema of the
required riddler version enumerates (`priv/schemas/presented-answer.schema.json`
at `v0.8.0`, its `element` definition; rd-ADR-0005's Amendment of
2026-11-24, "The enumeration and the fallback are said of elements", which
reads its Amendment of 2026-11-18, "The presented answer's schema enumerates
the node types", as said of element types). This record does not list
them: the components' tests enumerate them, and a kind riddler adds joins
in the release that renders it.

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

### 4. An unknown element kind is not rendered and blocks the submit; a component map renders a host's own

An element whose `"type"` is not one of the kinds the package renders
follows rd-ADR-0005's fallback (its Amendment of 2026-11-18, "The fallback
for a node type a client does not know", which its Amendment of 2026-11-24
says of an element): the component does not render that element, and does
not let the visitor submit that screen.

A host whose screens carry kinds of its own passes a component map, an
option of `RiddlerLiveView.Journey` that names, for an element type, the
host's function component that renders it. An element whose type the
map names is rendered by that component, and is a kind the LiveComponent
knows, so it does not block the submit.

### 5. Plain semantic HTML, with no styling shipped

The markup is plain semantic HTML: each element is drawn with the tag that
means what the element is, every component carries a `class` attribute,
and the markup carries stable `data-riddler-*` attributes a host's
stylesheet and tests can select on, among them `data-riddler-element` on
the markup of each element. No CSS framework
class appears in it, and the package ships no stylesheet. How it looks is
the host's.

### 6. A deterministic accessibility rule suite runs in the gate

Accessibility is held by a rule suite of ExUnit tests over the HTML the
components render. It is
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
- The package needs a riddler that carries those behaviours and presents a
  screen's `"elements"`: 0.8.0 or later.
- A host's engine is invisible here. Any execution engine that can answer
  `Riddler.Journey.Host`'s four callbacks can be rendered, and none is a
  dependency.
- Every submit and every back costs one call to the host's access module
  before the host's own callback.
- A screen carrying an element the package cannot render cannot be
  submitted from it, so no visitor is moved on from a screen they saw only
  part of.
- A host styles the markup from its own stylesheet, selecting on the
  `class` and `data-riddler-*` attributes, `data-riddler-element` among
  them; it inherits no look.
- A component that fails an accessibility rule fails the gate, not a later
  audit.

## Typespecs and worked example

This record names no types: the components, their attributes and the
component map's shape are the code half's, written against the decisions
above. riddler's typespecs for the scope and the two behaviours are in
rd-ADR-0005's Amendment of 2026-11-23, and the presented screen's in its
Amendment of 2026-11-24.

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
- The value `data-riddler-element` carries, and the names of the other
  `data-riddler-*` attributes.
- How the fallback tells the visitor that a screen cannot be submitted.
- Whether the component map may replace a kind the package renders.
- How progress is drawn.
- The anonymous visitor, streaming and the transport, which rd-ADR-0005's
  Amendment of 2026-11-23 leaves open, and a repeating section.
- An axe-core browser run.

---

## Amendment, 2026-11-26: a datetime question is drawn in the visitor's time zone, which the host supplies

Status: accepted (2026-11-27, riddler_live_view 0.1.0)

That the host supplies the visitor's time zone and that this package adds
the offset, recorded as an Amendment on this record before 0.1.0, was ruled
by the operator, 2026-11-26. riddler is unchanged by it. The shape of the
attribute, where the offset is added, what is drawn with no zone, and how a
wall time the clocks skip or pass twice is read are this entry's own,
written 2026-11-26 at `proposed`.

Every cite of riddler here is of the riddler-ex repository at the tag
`v0.9.0`, the commit published on Hex as riddler 0.9.0. The code this entry
describes is not on `main` when it is written, so it is cited by module and
function name, not by commit.

### Context

riddler's `datetime` format is an instant: a date and a time joined by `T`,
then `Z` or an offset `+HH:MM` or `-HH:MM`, with no fraction of a second
(rd-ADR-0002's Amendment of 2026-11-24, "`image`, `divider` and `link`, the
URL rule, the date and time formats, the hints and an accessible label",
"The date and time formats"). A presented `min`, `max` or value of that
format carries its offset too. The browser's `<input type="datetime-local">`
shows and submits a wall time with no offset, `2026-11-27T10:00`, which
riddler refuses as `response.format`, and its `min`, `max` and `value`
attributes take no offset either. Until this entry a datetime question was
drawn as a plain text input in which the visitor typed the instant.

### What the record now decides

**The attribute.** `RiddlerLiveView.Journey` takes a `time_zone` assign,
and `RiddlerLiveView.Components.text_question/1` and
`RiddlerLiveView.Components.elements/1` take a `time_zone` attribute: the
visitor's time zone as a zone name, such as `"America/Denver"`, which the
package resolves through the time zone database the host has configured
(`Calendar.get_time_zone_database/0`). The package adds no time zone
database and no dependency for one. A zone name rather than a fixed offset,
because the offset a zone keeps changes across a daylight saving change, and
the moment a visitor picks can fall on the other side of one from the moment
the screen is drawn.

**What is drawn.** With a zone the host's database resolves, a
`text_question` of the `datetime` format is drawn as
`<input type="datetime-local">`. Its presented `min`, `max` and value are
each read as the instant they name and drawn as the wall time that instant
is in the zone, `YYYY-MM-DDTHH:MM`, or `YYYY-MM-DDTHH:MM:SS` where the
presented text carries seconds; the input moves by the second, `step="1"`,
where any of them carries seconds. A presented value or bound not in
riddler's datetime shape, or whose wall time in the zone falls outside the
four-digit years the input takes, is not drawn. The same conversion draws a value
riddler presents again, a response already given included.

**Where the offset is added.** In `RiddlerLiveView.Journey`, on the submit,
before `Riddler.Journey.decode_submit/1` and the host's `submit/2`: the
response under the key of a presented `text_question` of the `datetime`
format, where it is a wall time the browser submits (`YYYY-MM-DDTHH:MM` or
`YYYY-MM-DDTHH:MM:SS`, a date that exists), is read in the zone and handed
on as riddler's datetime, the wall time as submitted with the offset in
force in the zone at that moment appended: `+HH:MM` or `-HH:MM`, or `Z`
where the offset is zero. No fraction of a second is written. Anything else
under that key, an empty field, a value that already carries an offset, a
fraction of a second or text that is not a wall time, is handed on
unchanged for riddler to validate; every other response is handed on as
before. So riddler validates an instant, and holds it to the question's
`min` and `max` as it holds any datetime.

**A wall time the clocks skip, and one they pass twice.** A wall time the
zone skips when its clocks go forward is read with the offset in force
before the change: it names the instant the clocks show that many minutes
after the change. A wall time the zone passes twice when its clocks go back
is read with the offset in force first, the earlier of the two instants.
Neither is refused: the visitor picked a time the input offered, and a
refusal would name no field the visitor could correct.

**With no zone.** Where the host passes no `time_zone`, or one its database
does not resolve (Elixir's default database resolves only `"Etc/UTC"`), a
datetime question is drawn as the plain text input it was, with no bounds,
and its value is handed on as typed. The zone is the host's to give; the
package does not guess one.

### What is unchanged

- riddler, and what it validates: the package writes riddler's shape and
  riddler reads it.
- The `date` and `time` formats, drawn and submitted as before.
- A host's own component, which is called with exactly the assigns it had
  and is not handed the zone.
- Decision 1: the zone is the host's value, held as an assign like the
  host's other options, and nothing a visitor typed is kept.

### Worked example

**Patron registration, a pickup appointment.** A branch library's host
presents a screen asking a new patron for a preferred pickup appointment,
a required `text_question` of the `datetime` format with `"min"`
`"2026-11-27T16:00Z"` and `"max"` `"2026-11-28T01:00Z"`, and embeds the
Journey with `time_zone="America/Denver"`, the branch's zone. The input is
drawn with `min="2026-11-27T09:00"` and `max="2026-11-27T18:00"`. The patron
picks 10:00 on 27 November; the browser submits `2026-11-27T10:00`, and the
host's `submit/2` receives `2026-11-27T10:00-07:00`, which
`Riddler.Screens.validate_screen/4` accepts. A patron who picks 08:59 is
refused by riddler with `response.out_of_range`, drawn beside the question.
A reminder set for `2026-03-08T02:30`, a time the clocks in Denver skip, is
handed on as `2026-03-08T02:30-07:00`; one set for `2026-11-01T01:30`, a
time they pass twice, as `2026-11-01T01:30-06:00`.

---

Noted 2026-11-27. What the code on `main` at `75dcd42`, the commit tagged
`v0.1.0` and published on Hex as riddler_live_view 0.1.0, does with the
component map, with a screen nothing can draw in full, and with a host or an
access module that fails at the component's boundary. Nothing above is
changed, and this note decides nothing: each paragraph says what the code
does where the record above leaves a question open or names where a thing
lives.

**The component map may not name a kind the package draws.** "What this does
not decide" leaves open whether the component map may replace a kind the
package renders. It may not. `RiddlerLiveView.Components.elements/1` and
`RiddlerLiveView.Components.unknown_kinds/2` raise `ArgumentError` for a
component map that names a kind the package draws, for an entry that is not a
string type paired with a function of one argument, and for a `components`
value that is not a map, each as a host's wiring and never a visitor's input
(the documentation of both functions, and the private `check_components!/1`
in `RiddlerLiveView.Components`). `RiddlerLiveView.Journey` does not catch
that raise (its moduledoc, "A host that answers outside its contract").

**How an unknown kind blocks the submit.** "What this does not decide" leaves
open how the fallback tells the visitor that a screen cannot be submitted.
Where a screen carries an element whose kind neither the package nor the
component map draws, `RiddlerLiveView.Components.elements/1` draws a notice
above the elements, a paragraph with `role="status"` carrying
`data-riddler-unknown`, in the package's own sentence or the host's
`unknown_text`, and every button it draws through
`RiddlerLiveView.Components.button/1` is drawn `disabled`, names the notice in
its `aria-describedby` and carries `data-riddler-blocked`. A disabled button
is the browser's to honour, so `RiddlerLiveView.Components.unknown_kinds/2`
answers the kinds nothing draws as the server-side check, and
`RiddlerLiveView.Journey` refuses a submit of such a screen whatever the
browser sends (`handle_event/3` for `"submit"`; its moduledoc, "A submit").
Decision 4's sentences hold as written.

**Where the component map is passed.** Decision 4 makes the component map an
option of `RiddlerLiveView.Journey`, and it is one: the Journey's
`components` assign. The map is read by
`RiddlerLiveView.Components.elements/1`, whose `components` attribute it is,
and the Journey passes its assign through to that attribute when it draws a
screen (`RiddlerLiveView.Journey.render/1`) and to `unknown_kinds/2` on a
submit. A host that lays out a screen of its own with the function components
passes the map to `elements/1` itself.

**A host or an access module that fails at the boundary.** The record does
not say what `RiddlerLiveView.Journey` does when a host callback or the
access module's check raises, throws or exits. It catches each at the
component's boundary (the private `guarded/2` in `RiddlerLiveView.Journey`).
On the host's `present/1` and on the access check it fails closed and draws
the one refusal Decision 3 names; on the host's `submit/2` and `back/2` it
keeps what is drawn. Either way it logs one error line naming the callback and
the kind of failure, the exception's module, `threw` or `exited`, and never
the exception's message, the answer or the event's parameters (its moduledoc,
"A host that answers outside its contract").

---

Noted 2026-11-27. The amendment above headed "a datetime question is drawn in
the visitor's time zone, which the host supplies" moves from `proposed` to
`accepted`, its Status line flipped in place and nothing else in it reworded.
The record's own Status stays proposed and is not flipped by this note, and
its row in `docs/adr/README.md` is unchanged. The flip was decided by the
conductor under a standing consent, 2026-11-27.

It shipped in riddler_live_view 0.1.0, the commit tagged `v0.1.0`
(`75dcd42`) and published on Hex; its code half is `b09f63a`, the commit that
added it. It was re-verified at the tag, which is `main`. What was read:

- The attribute: `RiddlerLiveView.Journey` takes a `time_zone` assign, and
  `RiddlerLiveView.Components.text_question/1` and
  `RiddlerLiveView.Components.elements/1` take a `time_zone` attribute. The
  zone is resolved by `DateTime.shift_zone/2` through the configured
  database (`RiddlerLiveView.LocalTime.zone/1`), and `deps/0` in `mix.exs`
  adds no time zone database.
- What is drawn: with a zone the database resolves, a `datetime` question is
  an `<input type="datetime-local">`; its value, `min` and `max` are drawn as
  the wall times they are in the zone, with seconds where the presented text
  carries them and `step="1"` where any does; a value or bound not in
  riddler's shape, or outside four-digit years in the zone, is not drawn
  (`RiddlerLiveView.LocalTime.local/2`).
- Where the offset is added: `RiddlerLiveView.Journey`'s submit adds it to
  the response of a presented `datetime` `text_question` before
  `Riddler.Journey.decode_submit/1` and the host's `submit/2`
  (`RiddlerLiveView.LocalTime.instant/2`), `Z` for a zero offset and no
  fraction of a second; an empty field, a value with an offset, a fraction
  of a second, a date that does not exist and text that is not a wall time
  are handed on unchanged.
- The gap and the overlap: a wall time the zone skips takes the offset in
  force before the change, and one it passes twice the first offset (the
  private `offset_at/2` in `RiddlerLiveView.LocalTime`).
- With no zone, or one the database does not resolve, the question is the
  plain text input with no bounds and its value is handed on as typed.
- What is unchanged holds: a host's own component is called with `element`,
  `moves`, `findings`, `finding_text` and `blocked_by` and no zone, and the
  `date` and `time` formats are drawn and submitted as before.
- The worked example is the suite's: `test/riddler_live_view/journey_test.exs`
  at `75dcd42` draws `min="2026-11-27T09:00"` and `max="2026-11-27T18:00"`,
  hands on `2026-11-27T10:00-07:00`, has `2026-11-27T08:59` refused by
  `Riddler.Screens.validate_screen/4` with `response.out_of_range`, and hands
  on `2026-03-08T02:30-07:00` and `2026-11-01T01:30-06:00`; the suite is
  green in CI at that commit.
- The context's cite, rd-ADR-0002's Amendment of 2026-11-24 and its "The date
  and time formats", reads as quoted at riddler's `v0.9.0`, the version
  `mix.exs` requires (`~> 0.9`).

One sentence is read, not changed: the amendment's opening calls its own
parts written "at `proposed`", and says the code it describes is not on
`main` when it is written. It was written so; the code is on `main` at
`b09f63a`, and the amendment now reads accepted, by this note.
