defmodule RiddlerLiveView.SecretNoEchoTest do
  @moduledoc """
  A secret question's value is drawn nowhere: not in the HTML a LiveView
  renders, not in its assigns after the submit event, not in a log line.

  `RegistrationLive` is a minimal LiveView that renders the secret question
  inside a form and handles the submit the way a host does: it hands what
  the visitor typed to the host, keeps none of it, and renders the question
  as riddler presents it next, `"held"` true. Its callbacks are called
  directly, so the assigns after the submit are the socket the submit
  answered.
  """

  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  @sentinel "pin-sentinel-5150"

  @pin %{
    "type" => "secret_question",
    "key" => "card_pin",
    "label" => "Library card PIN",
    "required" => true,
    "held" => false
  }

  defmodule RegistrationLive do
    use Phoenix.LiveView

    alias RiddlerLiveView.Components

    @impl true
    def mount(_params, session, socket) do
      {:ok, assign(socket, element: session["element"], host: session["host"])}
    end

    @impl true
    def handle_event("submit", %{"riddler-password" => %{"card_pin" => typed}}, socket) do
      send(socket.assigns.host, {:sealed, %{"card_pin" => %{"sealed" => seal(typed)}}})
      {:noreply, assign(socket, element: Map.put(socket.assigns.element, "held", true))}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <form phx-submit="submit">
        <Components.secret_question element={@element} />
      </form>
      """
    end

    defp seal(typed), do: Base.encode16(:crypto.hash(:sha256, typed))
  end

  defp mount_live(element) do
    session = %{"element" => element, "host" => self()}
    {:ok, socket} = RegistrationLive.mount(%{}, session, %Phoenix.LiveView.Socket{})
    socket
  end

  defp html(socket), do: rendered_to_string(RegistrationLive.render(socket.assigns))

  defp submit(socket, typed) do
    params = %{"riddler-password" => %{"card_pin" => typed}}
    {:noreply, socket} = RegistrationLive.handle_event("submit", params, socket)
    socket
  end

  # Mutation: keep the submitted params in RegistrationLive's assigns - goes red.
  # (The component holds no assigns of its own; the next test pins its markup.)
  test "a submitted secret is absent from the HTML, the assigns after submit and the log" do
    log =
      capture_log([level: :debug], fn ->
        socket = mount_live(@pin)
        refute html(socket) =~ @sentinel

        socket = submit(socket, @sentinel)

        refute inspect(socket.assigns, limit: :infinity) =~ @sentinel
        refute html(socket) =~ @sentinel
        assert html(socket) =~ "data-riddler-held"
      end)

    refute log =~ @sentinel
    assert_received {:sealed, %{"card_pin" => %{"sealed" => sealed}}}
    refute sealed =~ @sentinel
  end

  # Mutation: draw a finding's message where it has no author_message in
  # drawn_findings/3 - goes red.
  test "a finding on a secret question draws neither its message nor anything it quotes" do
    finding = %Riddler.Finding{
      code: "response.invalid_shape",
      message: "a message quoting #{@sentinel}",
      field: "type",
      element_key: "card_pin"
    }

    assigns = %{element: @pin, findings: [finding]}

    html =
      rendered_to_string(~H"""
      <RiddlerLiveView.Components.secret_question element={@element} findings={@findings} />
      """)

    refute html =~ @sentinel
    assert html =~ ~s(data-riddler-finding="response.invalid_shape")
    assert html =~ "This answer could not be read."
  end

  # Mutation: value the input, value={@element["value"]} in secret_question/1 -
  # goes red.
  test "a value the host's element carries is drawn nowhere, before or after the submit" do
    log =
      capture_log([level: :debug], fn ->
        socket = mount_live(Map.put(@pin, "value", @sentinel))
        refute html(socket) =~ @sentinel

        socket = submit(socket, "4417")

        refute html(socket) =~ @sentinel
        refute html(socket) =~ ~r/<input[^>]*\svalue=/
      end)

    refute log =~ @sentinel
  end
end
