defmodule RiddlerLiveView.Journey do
  @moduledoc """
  The LiveComponent a host's LiveView embeds to show one Journey.

  A host names the Journey and its own two modules, and this component does
  the rest of a visit: it asks the host where the Journey is, draws what
  `Riddler.Journey.present/3` answers for it, and hands back what the
  visitor submits. It steps nothing and stores nothing: every step is the
  host's, through the four callbacks of `Riddler.Journey.Host`.

      <.live_component
        module={RiddlerLiveView.Journey}
        id="registration"
        journey={@journey}
        host={Library.RegistrationHost}
        access={Library.PatronAccess}
        actor={@patron_id}
      />

  ## Assigns

    * `id` - required, as for every LiveComponent; it is also the prefix of
      every `id` the component's markup derives, unless `id_prefix` says
      otherwise, so two Journeys on one page carry no `id` twice.
    * `journey` - required, the host's name for the Journey, which the
      component passes to the host and never reads.
    * `host` - required, the host's module implementing
      `Riddler.Journey.Host`.
    * `access` - the host's module implementing `Riddler.Journey.Access`,
      and `actor`, who is asking, the host's own value. This version holds
      both and asks no access check yet: until it does, the host decides
      who may see a Journey before it embeds the component.
    * `components` - the component map `RiddlerLiveView.Components.elements/1`
      takes, for the host's own element kinds.
    * `finding_text` and `unknown_text` - passed to the components, as
      `RiddlerLiveView.Components` describes them.
    * `waiting_text` and `done_text` - the sentence drawn while the
      execution waits and once it is done.
    * `id_prefix` - the prefix of every `id` the markup derives, in place of
      `id`.
    * `class` - classes added to the component's own.

  `send_update(RiddlerLiveView.Journey, id: id, refresh: true)` asks the
  host again where the Journey is and draws the answer; any other update
  keeps the answer drawn.

  ## What is drawn

  The component asks the host's `present/1` when it mounts, and draws what
  it answers:

    * a screen as a form: `RiddlerLiveView.Components.frame/1` around
      `RiddlerLiveView.Components.elements/1`, then the Back control where
      the moves offer it;
    * waiting as a paragraph with `role="status"`, carrying the answer's
      `"reason"` as `data-riddler-reason`; where the answer carries
      `"retry_after_ms"`, the component sets a LiveView timer,
      `Phoenix.LiveView.send_update_after/4` to itself on a connected
      socket, and asks the host again when it fires; a new answer cancels a
      timer still pending;
    * done as a paragraph; the answer's `"result"` is the host's and is not
      drawn.

  The component's root carries `data-riddler-journey`, and
  `data-riddler-state` with the answer's `"state"`. A host callback that
  answers `{:error, :no_such_journey}` leaves nothing of the Journey drawn,
  and no submit or back reaches the host after it.

  ## A submit

  When the visitor presses a button, the component builds riddler's submit
  from the presented answer and the form, never from the form alone:

    * `"screen"` is the key of the screen presented, and a form sent from
      another screen is refused;
    * `"outcome"` is the pressed button's, and is refused unless the moves
      presented list it and a button presented on the screen raises it;
    * `"responses"` carries a response for each question presented on the
      screen, keyed by the question's `"key"`, and the form's value under
      the key of each presented element of a kind the component map names,
      where the form carries one; nothing else the form carries is handed
      on. The pressed button's outcome arrives under `"outcome"` and the
      screen's key under `"riddler-screen"`, so a question keyed
      `"outcome"` cannot be read from the form.

  A boolean question's submitted `"true"` becomes `true`, and an unticked
  one `false`, since riddler validates a boolean response as one of those.
  A choice question under `"many"` with nothing ticked sends `[]`. A secret
  question's empty field is left out of the responses, so a value already
  held stays held and an empty one is never handed on.

  A screen carrying an element nothing draws, as
  `RiddlerLiveView.Components.unknown_kinds/2` answers, is refused whatever
  the browser sends. The submit is then checked by
  `Riddler.Journey.decode_submit/1` and handed to the host's `submit/2`. The
  host validates the responses with `Riddler.Screens.validate_screen/4`,
  passing the key of the button whose outcome the submit names, which the
  host finds in its own document: a form submit carries the pressed
  button's `name` and `value` and nothing else of it.

  A host's `{:ok, answer}` is drawn in place of the screen. Its
  `{:error, findings}` is drawn beside the questions they name, and focus
  moves to the first finding on every refusal, the same first finding
  included. Back is handled the same way: the back request is refused unless
  it names the screen presented and the moves offered back, and then goes to
  the host's `back/2`.

  A refused submit or back request calls no host callback and changes
  nothing drawn.

  ## What the component holds

  The Journey's name, the host's modules and options, the answer drawn, the
  Journey's scope, the findings of the last refusal and a count of
  refusals: nothing a visitor typed. What a submit carries is handed to the
  host and not kept, so a secret question's value is in no assign after the
  submit and in no markup. The component logs nothing, and the secret
  question's input is named under `"riddler-password"`, which Phoenix's
  default `:filter_parameters` filters out of the line LiveView logs for
  each event; a host that changes that setting keeps a filter that
  matches `password`.
  """

  use Phoenix.LiveComponent

  alias Phoenix.LiveView.Socket
  alias Riddler.Journey
  alias RiddlerLiveView.Components

  @options [
    :id,
    :journey,
    :host,
    :access,
    :actor,
    :components,
    :finding_text,
    :unknown_text,
    :waiting_text,
    :done_text,
    :id_prefix,
    :class
  ]

  @defaults %{
    access: nil,
    actor: nil,
    components: %{},
    finding_text: %{},
    unknown_text: nil,
    waiting_text: "One moment.",
    done_text: "All done.",
    id_prefix: nil,
    class: nil
  }

  @question_types ~w(text_question secret_question choice_question boolean_question)

  @impl true
  @spec mount(Socket.t()) :: {:ok, Socket.t()}
  def mount(socket) do
    {:ok, assign(socket, answer: nil, scope: nil, findings: [], refusals: 0, retry: nil)}
  end

  @impl true
  @spec update(map(), Socket.t()) :: {:ok, Socket.t()}
  def update(assigns, socket) do
    first = not Map.has_key?(socket.assigns, :journey)
    changed = Map.has_key?(assigns, :journey) and assigns.journey != socket.assigns[:journey]

    socket =
      socket
      |> assign(if first, do: @defaults, else: %{})
      |> assign(Map.take(assigns, @options))

    if first, do: check_wiring!(socket.assigns)

    if first or changed or Map.get(assigns, :refresh) == true,
      do: {:ok, present(socket)},
      else: {:ok, socket}
  end

  @impl true
  @spec handle_event(String.t(), map(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_event("submit", params, socket) do
    with {:ok, screen, moves} <- presented_screen(socket),
         :ok <- same_screen(params["riddler-screen"], screen),
         [] <- Components.unknown_kinds(screen, socket.assigns.components),
         {:ok, _button} <- pressed_button(screen, moves, params["outcome"]),
         submit = %{
           "screen" => screen["key"],
           "outcome" => params["outcome"],
           "responses" => responses(screen, socket.assigns.components, params)
         },
         {:ok, submit} <- Journey.decode_submit(submit),
         :ok <- authorize(socket, :submit) do
      socket.assigns.host.submit(socket.assigns.journey, submit)
      |> step(socket)
    else
      _refused -> {:noreply, socket}
    end
  end

  def handle_event("back", params, socket) do
    with {:ok, screen, moves} <- presented_screen(socket),
         {:ok, %{"back" => true} = request} <- Journey.decode_submit(params),
         :ok <- same_screen(request["screen"], screen),
         true <- moves["back"] == true,
         :ok <- authorize(socket, :back) do
      socket.assigns.host.back(socket.assigns.journey, request)
      |> step(socket)
    else
      _refused -> {:noreply, socket}
    end
  end

  @impl true
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    assigns =
      assign(assigns,
        state: assigns.answer && assigns.answer["state"],
        prefix: assigns.id_prefix || assigns.id
      )

    ~H"""
    <div
      id={@id}
      class={["riddler-journey" | List.wrap(@class)]}
      data-riddler-journey
      data-riddler-state={@state}
    >
      <form
        :if={@state == "screen"}
        phx-submit="submit"
        phx-target={@myself}
        phx-value-riddler-screen={@answer["screen"]["key"]}
        class="riddler-form"
      >
        <Components.frame
          screen={@answer["screen"]}
          progress={@answer["progress"]}
          findings={@findings}
          finding_text={@finding_text}
          refusals={@refusals}
          id_prefix={@prefix}
        >
          <Components.elements
            screen={@answer["screen"]}
            moves={@answer["moves"]}
            components={@components}
            findings={@findings}
            finding_text={@finding_text}
            unknown_text={@unknown_text}
            id_prefix={@prefix}
          />
        </Components.frame>
        <Components.back screen={@answer["screen"]} moves={@answer["moves"]} target={@myself} />
      </form>
      <p
        :if={@state == "waiting"}
        role="status"
        class="riddler-waiting"
        data-riddler-waiting
        data-riddler-reason={@answer["reason"]}
      >
        {@waiting_text}
      </p>
      <p :if={@state == "done"} class="riddler-done" data-riddler-done>{@done_text}</p>
    </div>
    """
  end

  # A host that leaves out the Journey or its host module has wired the
  # component wrongly; no visitor's input reaches this.
  defp check_wiring!(assigns) do
    for key <- [:journey, :host], is_nil(assigns[key]) do
      raise ArgumentError, "RiddlerLiveView.Journey needs the #{inspect(key)} assign"
    end

    :ok
  end

  # Asks the host where the Journey is, and draws the answer.
  defp present(socket) do
    %{host: host, journey: journey} = socket.assigns

    with {:ok, scope, answer} <- host.present(journey),
         socket = assign(socket, scope: scope),
         :ok <- authorize(socket, :present) do
      show(socket, answer)
    else
      {:error, :no_such_journey} -> refuse(socket)
    end
  end

  # The access check's place, asked before each host callback that shows
  # or steps the Journey: `:present` when the answer is fetched, `:submit`
  # before `submit/2` and `:back` before `back/2`. It asks nothing yet and
  # answers `:ok`.
  defp authorize(_socket, _operation), do: :ok

  defp step({:ok, answer}, socket), do: {:noreply, show(socket, answer)}

  defp step({:error, :no_such_journey}, socket), do: {:noreply, refuse(socket)}

  defp step({:error, findings}, socket) when is_list(findings) do
    {:noreply, assign(socket, findings: findings, refusals: socket.assigns.refusals + 1)}
  end

  defp show(socket, answer) do
    assign(socket, answer: answer, findings: [], retry: retry(socket, answer))
  end

  defp refuse(socket), do: assign(socket, answer: nil, findings: [], retry: retry(socket, nil))

  # One timer at a time: whatever answer is drawn next, a pending retry is
  # cancelled first, and a new one is set only for a waiting answer that
  # carries a hint, and only on a connected socket.
  defp retry(socket, answer) do
    if socket.assigns.retry, do: Process.cancel_timer(socket.assigns.retry)

    case answer do
      %{"state" => "waiting", "retry_after_ms" => ms} when is_integer(ms) ->
        if connected?(socket),
          do: send_update_after(self(), __MODULE__, %{id: socket.assigns.id, refresh: true}, ms)

      _answer ->
        nil
    end
  end

  defp presented_screen(%{assigns: %{answer: %{"state" => "screen"} = answer}}),
    do: {:ok, answer["screen"], answer["moves"]}

  defp presented_screen(_socket), do: :error

  defp same_screen(key, %{"key" => key}) when is_binary(key), do: :ok
  defp same_screen(_key, _screen), do: :error

  # The button presented on the screen that raises the outcome, where the
  # moves list that outcome.
  defp pressed_button(screen, moves, outcome) when is_binary(outcome) do
    with true <- outcome in List.wrap(moves["outcomes"]),
         %{} = button <-
           Enum.find(
             List.wrap(screen["elements"]),
             &(&1["type"] == "button" and &1["outcome"] == outcome)
           ) do
      {:ok, button}
    else
      _ -> :error
    end
  end

  defp pressed_button(_screen, _moves, _outcome), do: :error

  # One response per question presented on the screen, read from the form
  # by the question's key; nothing else the form carries is handed on.
  defp responses(screen, components, params) do
    screen["elements"]
    |> List.wrap()
    |> Enum.flat_map(fn element -> response(element, components, params) end)
    |> Map.new()
  end

  defp response(%{"type" => type, "key" => key} = element, _components, params)
       when type in @question_types and is_binary(key) do
    case {type, fetch_response(type, params, key)} do
      {"boolean_question", {:ok, "true"}} -> [{key, true}]
      {"boolean_question", :error} -> [{key, false}]
      {"choice_question", :error} -> if element["select"] == "many", do: [{key, []}], else: []
      {"secret_question", {:ok, ""}} -> []
      {_type, {:ok, value}} -> [{key, value}]
      {_type, :error} -> []
    end
  end

  # An element of a host's own kind answers what the form carries under its
  # key, as the host's component drew it.
  defp response(%{"type" => type, "key" => key}, components, params)
       when is_binary(type) and is_binary(key) and is_map_key(components, type) do
    case Map.fetch(params, key) do
      {:ok, value} -> [{key, value}]
      :error -> []
    end
  end

  defp response(_element, _components, _params), do: []

  # A secret question's input is named under "riddler-password", so the
  # value is read from there; every other question's from its own key.
  defp fetch_response("secret_question", params, key) do
    case params do
      %{"riddler-password" => %{} = secrets} -> Map.fetch(secrets, key)
      _params -> :error
    end
  end

  defp fetch_response(_type, params, key), do: Map.fetch(params, key)
end
