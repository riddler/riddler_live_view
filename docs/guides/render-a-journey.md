# Render a Journey in a LiveView

This page shows how to put one visitor's Journey on a page with
`RiddlerLiveView.Journey`: the two modules your host writes, the one
component you embed, and what the visitor sees. It uses patron registration:
a visitor gets a library card, and the Journey is that one visitor's
execution through the screens.

It assumes you already present screens with `Riddler.Journey.present/3`; if
not, start from riddler's guide, [Present a Journey: a screen, waiting or
done](https://hexdocs.pm/riddler/present-a-journey.html).

## Write the two modules the component asks

The component starts nothing and steps nothing. It asks your host where a
Journey is, and it asks your access module whether the visitor may see it.
Both are riddler's behaviours:

- `Riddler.Journey.Host`, four callbacks: `start/2`, `present/1`, `submit/2`
  and `back/2`. The component calls `present/1`, `submit/2` and `back/2`.
- `Riddler.Journey.Access`, whose `member?/2` says whether an actor belongs to
  a scope.

A host's `present/1` answers the Journey's scope and what
`Riddler.Journey.present/3` answers for where the Journey is. The patron
registration host keeps the document, the status and the root on its own
execution record:

```elixir
defmodule Library.RegistrationHost do
  @behaviour Riddler.Journey.Host

  alias Riddler.Journey
  alias Riddler.Screens

  @impl true
  def start(path, scope) do
    # Start an execution of the Path under `scope`, and answer
    # {:ok, journey, answer}. See "Scope a Path to who may see it".
  end

  @impl true
  def present(journey) do
    with {:ok, execution} <- Library.Executions.fetch(journey),
         {:ok, answer} <-
           Journey.present(execution.document, execution.status, execution.root) do
      {:ok, execution.scope, answer}
    else
      _missing -> {:error, :no_such_journey}
    end
  end

  @impl true
  def submit(journey, submit) do
    with {:ok, execution} <- Library.Executions.fetch(journey),
         root = Library.Executions.with_responses(execution, submit["responses"]),
         button = pressed_button(execution.document, submit["outcome"]),
         :ok <- Screens.validate_screen(execution.document, submit["screen"], root, button),
         {:ok, execution} <- Library.Executions.advance(execution, submit["outcome"], root),
         {:ok, answer} <-
           Journey.present(execution.document, execution.status, execution.root) do
      {:ok, answer}
    else
      {:error, findings} when is_list(findings) -> {:error, findings}
      _missing -> {:error, :no_such_journey}
    end
  end

  @impl true
  def back(journey, _request) do
    # Move the execution back a screen and answer {:ok, answer}.
  end

  # The component hands the host the pressed button's outcome. The host
  # finds the button in its own document, because
  # Riddler.Screens.validate_screen/4 takes the button's key.
  defp pressed_button(document, outcome) do
    Enum.find_value(document.screens, fn screen ->
      Enum.find_value(screen.elements, fn
        %{type: "button", outcome: ^outcome, key: key} -> key
        _element -> nil
      end)
    end)
  end
end
```

Where `Library.Executions` keeps an execution, and how it moves from one
screen to the next, are the host's. What matters here is the answers: a
`{:ok, answer}` is drawn in place of the screen, an `{:error, findings}` is
drawn beside the questions the findings name, and an
`{:error, :no_such_journey}` is drawn as a refusal.

The access module says which visitors belong to which scope. Patron
registration scopes each Journey to the patron it is for:

```elixir
defmodule Library.PatronAccess do
  @behaviour Riddler.Journey.Access

  alias Riddler.Journey.Scope

  @impl true
  def member?(patron_id, %Scope{kind: "patron", id: id}), do: patron_id == id
  def member?(_patron_id, _scope), do: false

  @impl true
  def scopes(patron_id) do
    {:ok, scope} = Scope.new("patron", patron_id)
    [scope]
  end
end
```

## Embed the component

Put `RiddlerLiveView.Journey` in the LiveView that serves the registration
page. Pass the host's name for the Journey, the two modules and the actor, the
visitor the access module is asked about:

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

`journey`, `host` and `access` are required. A component mounted without an
`access` module, or with one that is not a loaded module exporting
`member?/2`, raises `ArgumentError`: that is wiring, not a visitor's input.
The `actor` is yours: the component hands it to the access module and never
reads it.

On mount the component asks `present/1`, asks `Riddler.Journey.Access.check/4`
with the scope `present/1` answered, and draws the answer. It asks the check
again before every submit and every back, so a membership you revoke while a
Journey is open refuses the next press.

## What the visitor sees

The answer's `"state"` decides what is drawn:

- A `"screen"` is drawn as a form: the screen's title, its elements, each
  through the component for its kind, and a Back button where the answer's
  moves offer one.
- `"waiting"` is drawn as a paragraph with `role="status"`. Where the answer
  carries `"retry_after_ms"`, the component asks `present/1` again after that
  many milliseconds, and checks access again, on a connected socket.
- `"done"` is drawn as a paragraph. The answer's `"result"` is yours and is
  not drawn.
- A Journey the visitor may not see, and a Journey that does not exist, are
  drawn as the same one refusal.

The words the component writes are its defaults. Replace them with the
assigns `waiting_text`, `done_text`, `refused_text` and `unknown_text`, and
the sentence drawn for a finding, code by code, with `finding_text`:

```heex
<.live_component
  module={RiddlerLiveView.Journey}
  id="registration"
  journey={@journey}
  host={Library.RegistrationHost}
  access={Library.PatronAccess}
  actor={@patron_id}
  done_text="Your library card is on its way."
  finding_text={%{"response.format" => "Check the email address."}}
/>
```

A finding the document's author wrote text for is drawn with the author's
text; `finding_text` replaces only the package's own sentence.

After your engine changes a Journey from outside the page, ask the component
to draw it again:

```elixir
send_update(RiddlerLiveView.Journey, id: "registration", refresh: true)
```

## Know what a submit sends

When the visitor presses a button, the component builds riddler's submit from
what was presented, never from the form alone. The `"responses"` it hands your
host's `submit/2` hold an entry, keyed by the question's key, for each question presented on
the screen that the form sent a value for (a single choice with nothing
picked is left out). A boolean question's response is `true` or
`false`, a choice question under `"many"` with nothing ticked is `[]`, and a
secret question left empty is left out so that a value already held stays
held. A submit that does not match what was presented, such as another screen
or an outcome no presented button raises, reaches nobody: the component
ignores it.

The text question's input is `type="email"` for the email format, `type="tel"`
for the phone format, `type="date"` and `type="time"` for the date and time
formats, and carries `required` where the question does. A date or time input
carries the question's `min` and `max`, and what it submits is already in
riddler's shape for the format, so your host passes it on as it comes. A
datetime question is drawn as a plain text input. A slider or a stepper
carries its bounds and step. No other input sets a `pattern`, `min` or
`max`, but the browser's own checks for the type, the bounds and `required`
still run, and can stop a submit with the browser's own message before your
host is asked. A host that wants every check left to riddler draws the
screen itself, with the components of `RiddlerLiveView.Components`
inside a form of its own, and adds `novalidate` there: the form
`RiddlerLiveView.Journey` draws carries no `novalidate`. A button that
declares `validates: false` carries `formnovalidate`, so the browser's checks
do not stop it; [Offer an authored skip](offer-an-authored-skip.md) shows
one.

## Style it

The markup is plain semantic HTML. Every component carries a `class`, such as
`riddler-journey` or `riddler-screen`, and stable `data-riddler-*` attributes
a stylesheet and a test can select on: `data-riddler-journey` and
`data-riddler-state` on the root, `data-riddler-element` and
`data-riddler-key` on each element, `data-riddler-finding` on each finding.
No CSS framework class appears in it and the package ships no stylesheet, so
the look is yours. Pass `class` to add classes to the component's own, and
`id_prefix` where two Journeys share a page so that no `id` is carried twice.

## See also

- `RiddlerLiveView.Journey` for every assign and every refusal.
- `RiddlerLiveView.Components` for each component's markup and attributes.
- [Scope a Path to who may see it](scope-a-path.md) for starting a Journey
  under a scope.
- [Draw an element of your own kind](draw-an-element-of-your-own-kind.md) for
  a screen element this package does not draw.
- [Offer an authored skip](offer-an-authored-skip.md) for a button that leaves
  a screen unfinished.
