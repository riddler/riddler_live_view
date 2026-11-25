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

  `RiddlerLiveView.Components` holds the screen's frame and the components
  for the `heading` and `text` elements. The LiveComponent and the
  components for the other element kinds are still to come.
  """
end
