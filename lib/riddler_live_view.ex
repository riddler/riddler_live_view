defmodule RiddlerLiveView do
  @moduledoc """
  Phoenix LiveView components for what Riddler presents.

  Riddler answers what one visitor sees at one step of a Journey: a screen
  of elements, a waiting state or a finished one. This package renders that
  answer as plain semantic HTML: a function component for each element kind,
  and one LiveComponent a host embeds to show a Journey step, collect what
  the visitor submits and hand it back to the host.

  The package depends on `riddler` and `phoenix_live_view` only. It does not
  start an execution, store a response or decide who may see a Journey: those
  stay the host's.

  `RiddlerLiveView.Components` holds the screen's frame, the Back control and
  a component for each element kind: `heading/1`, `text/1`, `image/1`,
  `divider/1`, `link/1`, `text_question/1`, `secret_question/1`,
  `choice_question/1`, `boolean_question/1` and `button/1`. Every question
  draws the findings a refused submit names, with the `findings` and
  `finding_text` attributes. `RiddlerLiveView.Journey` is
  the LiveComponent: it asks the host where a Journey is, asks the host's
  access module whether the visitor may see it, draws the answer and hands the
  host each submit and back request.

  The guides take one goal each:

    * [Render a Journey in a LiveView](render-a-journey.md)
    * [Scope a Path to who may see it](scope-a-path.md)
    * [Draw an element of your own kind](draw-an-element-of-your-own-kind.md)
    * [Offer an authored skip](offer-an-authored-skip.md)
  """
end
