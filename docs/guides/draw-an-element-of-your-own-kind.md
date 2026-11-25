# Draw an element of your own kind

This page shows how to have `RiddlerLiveView.Journey` draw an element whose
kind the package does not, and what the visitor can do on a screen that
carries one nothing draws. It uses the branch-library onboarding: a screen
that asks a new branch's staff to choose the branch on a map.

It assumes the component is embedded as in [Render a Journey in a
LiveView](render-a-journey.md).

## What the package does with a kind it does not know

The package draws the element kinds riddler presents: `heading`, `text`,
`text_question`, `secret_question`, `choice_question`, `boolean_question` and
`button`. An element of any other `"type"` is not drawn, and the visitor may
not submit the screen it is on, because a visitor who is moved on from a screen
they saw only part of has answered something they did not see. In place of
the element the component draws a notice above the screen's elements, a
status region saying that part of the screen cannot be shown, and draws every
button disabled with `data-riddler-blocked`. The component also refuses the
submit whatever a browser sends: a disabled button is the browser's to honour.

Say what the notice says with the `unknown_text` assign.

## Register your kind with a component map

Pass a component map in the `components` assign. Its keys are element types
and its values are your function components, each of arity 1:

```heex
<.live_component
  module={RiddlerLiveView.Journey}
  id="onboarding"
  journey={@journey}
  host={Library.OnboardingHost}
  access={Library.BranchAccess}
  actor={@staff_id}
  components={%{"branch_map" => &LibraryWeb.Elements.branch_map/1}}
/>
```

The component is called with exactly these assigns: `element`, `moves`,
`findings`, `finding_text` and `blocked_by`. It is called as a plain function,
so the defaults of any `attr` it declares are not applied. A kind the map
names is a kind the component knows, so a screen carrying one is not blocked.

A function component for the branch map reads what the element carries and
draws a form control named by the element's key:

```elixir
defmodule LibraryWeb.Elements do
  use Phoenix.Component

  def branch_map(assigns) do
    ~H"""
    <label
      class="branch-map"
      data-riddler-element="branch_map"
      data-riddler-key={@element["key"]}
    >
      Branch
      <select name={@element["key"]}>
        <option :for={branch <- Library.Branches.open()} value={branch.id}>
          {branch.name}
        </option>
      </select>
    </label>
    """
  end
end
```

Put `data-riddler-element` and `data-riddler-key` on the markup, as the
package's own components do, so a stylesheet and a test select on your kind
the way they select on the others. The component map may not name a kind the
package draws: that raises `ArgumentError` when the screen is drawn, as does a
value that is not a function of one argument.

## What a submit carries for your kind

The form's value under the element's `"key"` is the element's response: the
`<select>` above, named by its key, answers `"B-12"` under `"pickup_branch"`.
The component hands the host's `submit/2` that value, a string, in
`"responses"` under the key, and carries no response for a key the form sent no
value under. It hands on nothing else the form carries.

In riddler 0.8.0, `Riddler.Journey.present/3` and
`Riddler.Screens.resolve_screen/3` keep only the `type` and the `key` of an
element whose type riddler does not know, so everything the
component draws beside them comes from the host: the open branches above come
from `Library.Branches`, not from the element. The same release's
`Riddler.Screens.Document.validate/1` refuses a type it does not know with
`document.unknown_type`, so the host decides whether a document that carries
your kind is one it saves and presents; this package reads only what
`Riddler.Journey.present/3` answers.

## Draw the notice yourself

A host that draws screens with the function components instead of the
LiveComponent asks which kinds nothing draws with
`RiddlerLiveView.Components.unknown_kinds/2`, passing the screen and the same
component map. It answers each kind once, in the order the screen carries
them, and `[]` where every element is drawn. Refuse the submit of a screen
that answers anything else.

## See also

- `RiddlerLiveView.Components`, "Elements of a kind the package does not
  draw", for the notice and the buttons it blocks.
- [Render a Journey in a LiveView](render-a-journey.md) for the component.
