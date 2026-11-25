# Offer an authored skip

This page shows how to let a visitor leave a screen unfinished, by authoring a
button that skips it. It uses patron registration: a visitor who does not want
to choose a PIN yet presses "Finish later" and moves on.

It assumes the component is embedded as in [Render a Journey in a
LiveView](render-a-journey.md).

## Why a skip is authored

`RiddlerLiveView.Journey` offers no generic skip control, and neither does
riddler. A skip is a button the document's author writes, with an outcome of
its own, so the screen says what the press means and the host's engine decides
where it goes. The package draws it as it draws any button.

## Author the button

Add a `button` element with its own outcome and `"validates": false` beside
the button that continues. `validates` defaults to `true`, and `false` is what
lets the press leave a half-filled screen without an error:

```elixir
%{
  "key" => "patron_details",
  "title" => "Get your library card",
  "elements" => [
    %{
      "type" => "text_question",
      "key" => "reminder_email",
      "label" => "Email for due-date reminders",
      "required" => true,
      "format" => "email"
    },
    %{
      "type" => "button",
      "key" => "details_next",
      "label" => "Continue",
      "outcome" => "details_submitted"
    },
    %{
      "type" => "button",
      "key" => "details_later",
      "label" => "Finish later",
      "outcome" => "details_deferred",
      "validates" => false,
      "style" => "secondary"
    }
  ]
}
```

`"style"` is a name the renderer owns. The package carries it as
`data-riddler-style` and reads nothing in it, so a stylesheet can make the skip
look quieter than the button beside it.

## What the package draws

The skip is a `<button type="submit">` that carries the outcome as its value,
`formnovalidate`, `data-riddler-outcome="details_deferred"` and
`data-riddler-validates="false"`. `formnovalidate` stops the browser's own
checks, such as `required`, from refusing a press of this button, so the
visitor leaves with the email left empty.

When the visitor presses it the component builds the submit as for any button:
it refuses it unless the moves presented list `details_deferred` and a button
presented on the screen raises it, and hands the host a submit whose
`"outcome"` is `"details_deferred"` and whose `"responses"` hold what the
visitor had entered.

## Let the host honour it

The browser's `formnovalidate` is not the check that matters. The host checks
the responses with `Riddler.Screens.validate_screen/4`, passing the key of the
pressed button, and riddler reads that button's `validates`:

```elixir
# pressed_button/2 is the helper from "Render a Journey in a LiveView".
def submit(journey, submit) do
  alias Riddler.Screens

  with {:ok, execution} <- Library.Executions.fetch(journey),
       root = Library.Executions.with_responses(execution, submit["responses"]),
       button_key = pressed_button(execution.document, submit["outcome"]),
       :ok <- Screens.validate_screen(execution.document, submit["screen"], root, button_key) do
    # `:ok` for details_deferred even with the email missing; the host's
    # engine moves on by the outcome, as for any other.
    Library.Executions.advance(execution, submit["outcome"], root)
  end
end
```

`validate_screen/4` answers `:ok` for a button declaring `validates` as `false`
without running a check. The arity-3 form presses no button and so checks
everything, which is why the host passes the key. What the skip means then, such
as which screen follows `details_deferred` and whether an empty email is kept,
is the host engine's: the package only raises the outcome.

## Leave the visitor a way back

A skip leaves forward. To let the visitor go back as well, give the screen's
status `"back" => true`, as riddler's [Let the visitor go
back](https://hexdocs.pm/riddler/present-a-journey.html#let-the-visitor-go-back)
shows. The component draws the Back control, a `<button type="button">` that
submits no form, where the answer's moves say so, and asks the access check
before it calls the host's `back/2`.

## See also

- `RiddlerLiveView.Components.button/1` for the attributes a button carries.
- [Render a Journey in a LiveView](render-a-journey.md) for the component.
- `Riddler.Screens.validate_screen/4` for the check that honours `validates`.
