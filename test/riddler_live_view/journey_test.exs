defmodule RiddlerLiveView.JourneyTest do
  @moduledoc """
  `RiddlerLiveView.Journey` driven through its LiveComponent callbacks.

  `RegistrationHost` is a host as `Riddler.Journey.Host` describes one: its
  engine is a status and a root kept in the test process, it answers
  through `Riddler.Journey.present/3`, validates a submit with
  `Riddler.Screens.validate_screen/4` and seals a secret before it keeps
  it. It reports every callback it is handed to the test process, so a test
  can say a callback was never called.
  """

  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias Phoenix.LiveComponent.CID
  alias Phoenix.LiveView.Socket
  alias Plug.Conn.Query
  alias Riddler.Journey.Scope
  alias Riddler.Screens.Document
  alias RiddlerLiveView.Journey

  @sentinel "pin-sentinel-7731"

  defmodule LoggedLive do
    use Phoenix.LiveView

    @impl true
    def render(assigns), do: ~H""
  end

  @document %{
    "schema_version" => 2,
    "id" => "patron_registration",
    "screens" => [
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
            "type" => "secret_question",
            "key" => "card_pin",
            "label" => "Choose a PIN for your card",
            "required" => true
          },
          %{
            "type" => "boolean_question",
            "key" => "agrees_to_rules",
            "label" => "I agree to the lending rules",
            "required" => true
          },
          %{
            "type" => "choice_question",
            "key" => "interests",
            "label" => "What do you like to borrow?",
            "select" => "many",
            "answer_options" => [
              %{"value" => "books", "label" => "Books"},
              %{"value" => "films", "label" => "Films"}
            ]
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
            "validates" => false
          }
        ]
      },
      %{
        "key" => "card_pickup",
        "title" => "Pick up your card",
        "elements" => [
          %{"type" => "text", "key" => "pickup_note", "text" => "Bring a proof of address."},
          %{
            "type" => "button",
            "key" => "pickup_done",
            "label" => "Done",
            "outcome" => "pickup_confirmed"
          }
        ]
      },
      %{
        "key" => "branch_rating",
        "title" => "Rate your branch",
        "elements" => [
          %{"type" => "rating_question", "key" => "branch_stars", "label" => "Stars"},
          %{
            "type" => "button",
            "key" => "rating_next",
            "label" => "Continue",
            "outcome" => "rated"
          }
        ]
      }
    ]
  }

  defmodule RegistrationHost do
    @behaviour Riddler.Journey.Host

    alias Riddler.Journey
    alias Riddler.Journey.Scope
    alias Riddler.Screens

    @next %{
      "details_submitted" => "card_pickup",
      "details_deferred" => "card_pickup",
      "rated" => "card_pickup",
      "pickup_confirmed" => :waiting
    }

    @impl true
    def start(_path, _scope), do: {:error, :no_such_journey}

    @impl true
    def present(journey),
      do: misbehave(:present, journey, fn -> keep_present(journey) end)

    defp keep_present(journey) do
      send(self(), {:host, :present, journey})

      case Process.get({:journey, journey}) do
        nil -> {:error, :no_such_journey}
        engine -> {:ok, scope(), answer(engine)}
      end
    end

    @impl true
    def submit(journey, submit),
      do: misbehave(:submit, submit, fn -> keep_submit(journey, submit) end)

    defp keep_submit(journey, submit) do
      send(self(), {:host, :submit, journey, submit})

      with %{} = engine <- Process.get({:journey, journey}) || {:error, :no_such_journey},
           {:ok, root} <- accept(engine, submit) do
        engine = %{
          engine
          | root: root,
            status: next_status(submit["outcome"], engine.status)
        }

        Process.put({:journey, journey}, engine)
        {:ok, answer(engine)}
      end
    end

    @impl true
    def back(journey, request),
      do: misbehave(:back, request, fn -> keep_back(journey, request) end)

    defp keep_back(journey, request) do
      send(self(), {:host, :back, journey, request})

      case Process.get({:journey, journey}) do
        nil ->
          {:error, :no_such_journey}

        engine ->
          engine = %{engine | status: {:screen, "patron_details"}}
          Process.put({:journey, journey}, engine)
          {:ok, answer(engine)}
      end
    end

    # A test sets {:misbehave, callback} to make the host answer outside its
    # contract; the raise carries what the host was handed, as a careless
    # host's match error would.
    defp misbehave(callback, handed, fun) do
      case Process.get({:misbehave, callback}) do
        nil -> fun.()
        :raise -> raise ArgumentError, "the host was handed #{inspect(handed)}"
        :throw -> throw(handed)
        :exit -> exit(handed)
        {:answer, answer} -> answer
      end
    end

    # An outcome the engine has no move for leaves the Journey where it is.
    defp next_status(outcome, status) do
      case Map.fetch(@next, outcome) do
        {:ok, :waiting} -> {:waiting, %{"retry_after_ms" => 5}}
        {:ok, screen} -> {:screen, screen, %{"back" => true}}
        :error -> status
      end
    end

    defp accept(engine, submit) do
      %{"screen" => screen, "outcome" => outcome, "responses" => responses} = submit
      document = engine.document
      held = Map.get(engine.root, "responses", %{})
      root = Map.put(engine.root, "responses", Map.merge(held, responses))

      with :ok <- Screens.validate_screen(document, screen, root, button_key(document, outcome)),
           {:ok, sealed} <- Screens.seal_secrets(document, screen, root["responses"], &seal/1) do
        {:ok, Map.put(root, "responses", sealed)}
      end
    end

    # The host finds the pressed button by the outcome in its own document.
    defp button_key(document, outcome) do
      Enum.find_value(document.screens, fn screen ->
        Enum.find_value(screen.elements, fn
          %{type: "button", outcome: ^outcome, key: key} -> key
          _element -> nil
        end)
      end)
    end

    defp seal(plaintext), do: {:ok, Base.encode16(:crypto.hash(:sha256, plaintext))}

    defp answer(engine) do
      {:ok, answer} = Journey.present(engine.document, engine.status, engine.root)
      answer
    end

    defp scope do
      {:ok, scope} = Scope.new("patron", "P-1001")
      scope
    end
  end

  defmodule PatronAccess do
    @moduledoc false
    @behaviour Riddler.Journey.Access

    alias Riddler.Journey.Scope

    # A patron belongs to their own registration's scope until the test
    # revokes the membership with {:revoked, patron_id}.
    @impl true
    def member?(patron_id, %Scope{kind: "patron", id: id}) do
      if Process.get({:misbehave, :access}) == :raise,
        do: raise(ArgumentError, "the access module was asked about #{inspect(patron_id)}")

      patron_id == id and not Process.get({:revoked, patron_id}, false)
    end

    def member?(_patron_id, _scope), do: false

    @impl true
    def scopes(patron_id) do
      {:ok, scope} = Scope.new("patron", patron_id)
      [scope]
    end

    # Reports each operation asked, so a test can say which was asked.
    @impl true
    def allowed?(_patron_id, _scope, operation) do
      send(self(), {:access, operation})
      true
    end
  end

  defmodule PatronAccess.Other do
    @moduledoc false
    @behaviour Riddler.Journey.Access

    @impl true
    defdelegate member?(patron_id, scope), to: PatronAccess

    @impl true
    defdelegate scopes(patron_id), to: PatronAccess
  end

  setup do
    document = Document.admit(@document)
    put_engine("J-1", %{document: document, status: {:screen, "patron_details"}, root: %{}})
    %{document: document}
  end

  defp put_engine(journey, engine), do: Process.put({:journey, journey}, engine)

  defp engine(journey), do: Process.get({:journey, journey})

  defp set_status(journey, status), do: put_engine(journey, %{engine("J-1") | status: status})

  defp mount_journey(assigns \\ %{}) do
    socket = %Socket{assigns: %{__changed__: %{}, myself: %CID{cid: 1}}, transport_pid: self()}
    {:ok, socket} = Journey.mount(socket)

    assigns =
      Map.merge(
        %{
          id: "registration",
          journey: "J-1",
          host: RegistrationHost,
          access: PatronAccess,
          actor: "P-1001"
        },
        assigns
      )

    {:ok, socket} = Journey.update(assigns, socket)
    socket
  end

  defp html(socket), do: rendered_to_string(Journey.render(socket.assigns))

  defp event(socket, name, params) do
    {:noreply, socket} = Journey.handle_event(name, params, socket)
    socket
  end

  defp form(outcome, fields) do
    Map.merge(%{"riddler-screen" => "patron_details", "outcome" => outcome}, fields)
  end

  @filled %{
    "reminder_email" => "ada@example.org",
    "riddler-password" => %{"card_pin" => "4321"},
    "agrees_to_rules" => "true",
    "interests" => ["books"]
  }

  defp ids(html),
    do: ~r/\sid="([^"]+)"/ |> Regex.scan(html, capture: :all_but_first) |> List.flatten()

  describe "mount" do
    # Mutation: draw nothing for a screen answer - goes red.
    test "asks the host where the Journey is and draws the screen in a form" do
      socket = mount_journey()
      html = html(socket)

      assert_received {:host, :present, "J-1"}
      assert html =~ ~s(data-riddler-journey)
      assert html =~ ~s(data-riddler-state="screen")
      assert html =~ ~s(phx-submit="submit")
      assert html =~ ~s(phx-value-riddler-screen="patron_details")
      assert html =~ ~s(data-riddler-screen="patron_details")
      assert html =~ ~s(data-riddler-key="reminder_email")
      assert html =~ ~s(data-riddler-outcome="details_submitted")
      assert html =~ ~s(name="outcome")
      assert [_form] = Regex.scan(~r/<form\b[^>]*\sphx-target="1"/, html)
    end

    # Mutation: drop class, finding_text or unknown_text on the way to the components - goes red.
    test "passes the host's class and texts to the markup it draws" do
      fields = Map.put(@filled, "reminder_email", "ada")

      html =
        mount_journey(%{
          class: "signup-journey",
          finding_text: %{"response.format" => "Check it."}
        })
        |> event("submit", form("details_submitted", fields))
        |> html()

      assert html =~ ~s(class="riddler-journey signup-journey")
      assert html =~ "Check it."

      set_status("J-1", {:screen, "branch_rating"})
      html = mount_journey(%{unknown_text: "Ask at the desk."}) |> html()

      assert html =~ ~s(data-riddler-unknown="rating_question")
      assert html =~ "Ask at the desk."
      assert html =~ ~r/<button\b[^>]*\sdisabled/
    end

    # Mutation: drop the changed-Journey branch of update/2 - goes red.
    test "presents another Journey when the host passes one" do
      put_engine("J-2", %{engine("J-1") | status: :done})
      socket = mount_journey()
      assert_received {:host, :present, "J-1"}

      {:ok, socket} = Journey.update(%{id: "registration", journey: "J-2"}, socket)

      assert_received {:host, :present, "J-2"}
      assert html(socket) =~ ~s(data-riddler-state="done")
    end

    # Mutation: derive ids from "riddler" whatever the Journey's id - goes red.
    test "derives every id from the component's id, so two Journeys share none" do
      put_engine("J-2", engine("J-1"))
      one = mount_journey() |> html() |> ids()
      two = mount_journey(%{id: "renewal", journey: "J-2"}) |> html() |> ids()

      assert "registration-element-reminder_email" in one
      assert "registration-screen-patron_details-title" in one
      assert "renewal-element-reminder_email" in two
      assert MapSet.disjoint?(MapSet.new(one), MapSet.new(two))
    end

    test "takes an id_prefix in place of the id" do
      html = mount_journey(%{id_prefix: "signup"}) |> html()

      assert html =~ ~s(id="signup-element-reminder_email")
      refute html =~ ~s(id="registration-element-)
    end

    # Mutation: leave out the journey check in check_wiring! - goes red.
    test "raises ArgumentError without a Journey or a host module" do
      socket = %Socket{assigns: %{__changed__: %{}, myself: %CID{cid: 1}}, transport_pid: self()}
      {:ok, socket} = Journey.mount(socket)

      assert_raise ArgumentError, ~r/:journey/, fn ->
        Journey.update(%{id: "registration", host: RegistrationHost}, socket)
      end

      assert_raise ArgumentError, ~r/:host/, fn ->
        Journey.update(%{id: "registration", journey: "J-1"}, socket)
      end
    end

    # Mutation: draw the screen held before a host's refusal - goes red.
    test "draws nothing of a Journey the host does not have" do
      html = mount_journey(%{journey: "J-404"}) |> html()

      refute html =~ "data-riddler-state"
      refute html =~ "<form"
      refute html =~ "data-riddler-screen"
    end

    # Mutation: present on every update - goes red.
    test "keeps the answer drawn on an update that does not ask for a refresh" do
      socket = mount_journey()
      assert_received {:host, :present, "J-1"}

      {:ok, _socket} = Journey.update(%{id: "registration", finding_text: %{}}, socket)
      refute_received {:host, :present, _journey}
    end
  end

  describe "a submit" do
    # Mutation: pass the ticked checkbox's "true" through unconverted - goes red.
    test "hands the host the presented screen, the outcome and a response per question" do
      socket = mount_journey() |> event("submit", form("details_submitted", @filled))

      assert_received {:host, :submit, "J-1",
                       %{
                         "screen" => "patron_details",
                         "outcome" => "details_submitted",
                         "responses" => %{
                           "reminder_email" => "ada@example.org",
                           "card_pin" => "4321",
                           "agrees_to_rules" => true,
                           "interests" => ["books"]
                         }
                       }}

      assert html(socket) =~ ~s(data-riddler-screen="card_pickup")
      assert socket.assigns.findings == []
    end

    # Mutation: leave an unticked boolean or an empty "many" choice out - goes red.
    test "sends false for an unticked boolean and [] for a many choice with nothing ticked" do
      fields = Map.drop(@filled, ["agrees_to_rules", "interests"])
      socket = mount_journey() |> event("submit", form("details_submitted", fields))

      assert_received {:host, :submit, "J-1", %{"responses" => responses}}
      assert %{"agrees_to_rules" => false, "interests" => []} = responses

      assert [%{code: "response.required", element_key: "agrees_to_rules"}] =
               socket.assigns.findings
    end

    # Mutation: hand on every key the form carries - goes red.
    test "hands on nothing the form carries beyond the presented questions" do
      fields = Map.merge(@filled, %{"is_staff" => "true", "_target" => ["reminder_email"]})
      mount_journey() |> event("submit", form("details_submitted", fields))

      assert_received {:host, :submit, "J-1", %{"responses" => responses}}

      assert Map.keys(responses) |> Enum.sort() ==
               ~w(agrees_to_rules card_pin interests reminder_email)
    end

    # Mutation: hand on an empty secret field as "" - goes red.
    test "leaves an empty secret field out, so a held value stays held" do
      socket = mount_journey() |> event("submit", form("details_submitted", @filled))
      assert_received {:host, :submit, "J-1", _first}

      socket = event(socket, "back", %{"screen" => "card_pickup", "back" => true, "value" => ""})
      assert html(socket) =~ ~s(data-riddler-held)

      fields = Map.put(@filled, "riddler-password", %{"card_pin" => ""})
      socket = event(socket, "submit", form("details_submitted", fields))

      assert_received {:host, :submit, "J-1", %{"responses" => responses}}
      refute Map.has_key?(responses, "card_pin")
      assert %{"card_pin" => %{"sealed" => _sealed}} = engine("J-1").root["responses"]
      assert html(socket) =~ ~s(data-riddler-screen="card_pickup")
    end

    # Mutation: accept any outcome in pressed_button/3 - goes red.
    test "refuses an outcome the moves did not list, without calling the host" do
      socket = mount_journey()

      for outcome <- ["card_issued", "pickup_confirmed", "", nil] do
        params = form(outcome, @filled)
        refused = event(socket, "submit", params)

        refute_received {:host, :submit, _journey, _submit}
        assert refused.assigns == socket.assigns
      end

      refused = event(socket, "submit", Map.delete(form("x", @filled), "outcome"))
      refute_received {:host, :submit, _journey, _submit}
      assert refused.assigns == socket.assigns
    end

    # Mutation: skip same_screen/2 on a submit - goes red.
    test "refuses a form sent from a screen other than the one presented" do
      socket = mount_journey()

      for screen <- ["card_pickup", nil] do
        params = Map.put(form("details_submitted", @filled), "riddler-screen", screen)
        refused = event(socket, "submit", params)

        refute_received {:host, :submit, _journey, _submit}
        assert refused.assigns == socket.assigns
      end
    end

    # Mutation: skip the unknown_kinds/2 check on a submit - goes red.
    test "refuses a screen carrying an element nothing draws" do
      set_status("J-1", {:screen, "branch_rating"})
      socket = mount_journey()

      params = %{"riddler-screen" => "branch_rating", "outcome" => "rated", "branch_stars" => "5"}
      refused = event(socket, "submit", params)

      refute_received {:host, :submit, _journey, _submit}
      assert refused.assigns == socket.assigns
    end

    test "hands on a host kind's value where the component map names the kind" do
      set_status("J-1", {:screen, "branch_rating"})

      stars = fn assigns ->
        Phoenix.HTML.raw("<p class=\"stars\">#{assigns.element["key"]}</p>")
      end

      socket = mount_journey(%{components: %{"rating_question" => stars}})
      assert html(socket) =~ ~s(<p class="stars">branch_stars</p>)
      refute html(socket) =~ "data-riddler-unknown"

      params = %{"riddler-screen" => "branch_rating", "outcome" => "rated", "branch_stars" => "5"}
      event(socket, "submit", params)

      assert_received {:host, :submit, "J-1", %{"responses" => %{"branch_stars" => "5"}}}
    end

    test "refuses a submit while no screen is presented" do
      set_status("J-1", :done)
      socket = mount_journey()
      refused = event(socket, "submit", form("details_submitted", @filled))

      refute_received {:host, :submit, _journey, _submit}
      assert refused.assigns == socket.assigns
    end

    # Mutation: reset the findings on a host's {:error, findings} - goes red.
    test "draws the host's findings beside the questions they name" do
      fields = Map.put(@filled, "reminder_email", "ada")
      socket = mount_journey() |> event("submit", form("details_submitted", fields))
      html = html(socket)

      assert html =~ ~s(data-riddler-finding="response.format")
      assert html =~ ~s(id="registration-element-reminder_email-finding-1")
      assert html =~ ~s(data-riddler-screen="patron_details")
    end

    # Mutation: keep the refusal count fixed across refusals - goes red.
    test "moves focus to the first finding on every refusal, the same one included" do
      fields = Map.put(@filled, "reminder_email", "ada")
      socket = mount_journey() |> event("submit", form("details_submitted", fields))
      first = html(socket)
      socket = event(socket, "submit", form("details_submitted", fields))
      second = html(socket)

      target = ~s(data-riddler-focus="registration-element-reminder_email-finding-1")
      assert first =~ target
      assert second =~ target
      assert first =~ ~s(id="registration-element-reminder_email-finding-1-focus-1")
      assert second =~ ~s(id="registration-element-reminder_email-finding-1-focus-2")
      refute second =~ ~s(id="registration-element-reminder_email-finding-1-focus-1")
    end

    test "draws nothing of the Journey once the host answers it does not have it" do
      socket = mount_journey()
      Process.delete({:journey, "J-1"})
      socket = event(socket, "submit", form("details_submitted", @filled))

      refute html(socket) =~ "<form"
      refute html(socket) =~ "data-riddler-state"
    end
  end

  describe "the secret question's value" do
    # Mutation: keep the submitted params in the Journey's assigns - goes red.
    test "is absent from the assigns after the submit, from the markup and from the log" do
      log =
        capture_log([level: :debug], fn ->
          socket = mount_journey()

          refused =
            event(
              socket,
              "submit",
              form("details_submitted", %{
                @filled
                | "reminder_email" => "ada",
                  "riddler-password" => %{"card_pin" => @sentinel}
              })
            )

          refute inspect(refused.assigns, limit: :infinity, printable_limit: :infinity) =~
                   @sentinel

          refute html(refused) =~ @sentinel

          accepted =
            event(
              socket,
              "submit",
              form("details_submitted", %{
                @filled
                | "riddler-password" => %{"card_pin" => @sentinel}
              })
            )

          refute inspect(accepted.assigns, limit: :infinity, printable_limit: :infinity) =~
                   @sentinel

          refute html(accepted) =~ @sentinel

          back = event(accepted, "back", %{"screen" => "card_pickup", "back" => true})
          refute html(back) =~ @sentinel
          assert html(back) =~ ~s(data-riddler-held)
        end)

      refute log =~ @sentinel
    end

    # Mutation: name the secret question's input by its key alone - goes red.
    test "is filtered out of the line LiveView logs for the submit event" do
      html = mount_journey() |> html()

      [name] =
        Regex.run(~r/<input type="password"[^>]*\sname="([^"]+)"/, html, capture: :all_but_first)

      typed = Query.decode(URI.encode_www_form(name) <> "=" <> @sentinel)
      params = Map.merge(form("details_submitted", @filled), typed)

      log =
        capture_log([level: :debug], fn ->
          :telemetry.execute(
            [:phoenix, :live_component, :handle_event, :start],
            %{system_time: System.system_time()},
            %{
              socket: %Socket{view: LoggedLive},
              component: Journey,
              event: "submit",
              params: params
            }
          )
        end)

      assert log =~ "HANDLE EVENT"
      assert log =~ "reminder_email"
      refute log =~ @sentinel
    end
  end

  describe "back" do
    test "hands the host the back request where the moves offer back" do
      socket = mount_journey() |> event("submit", form("details_submitted", @filled))
      assert html(socket) =~ ~s(data-riddler-back)

      assert html(socket) =~
               ~r/<button\b[^>]*phx-click="[^"]*&quot;target&quot;:1[^"]*"[^>]*data-riddler-back/

      socket = event(socket, "back", %{"screen" => "card_pickup", "back" => true, "value" => ""})

      assert_received {:host, :back, "J-1",
                       %{"screen" => "card_pickup", "back" => true} = request}

      assert map_size(request) == 2
      assert html(socket) =~ ~s(data-riddler-screen="patron_details")
    end

    # Mutation: accept any back request whatever the moves - goes red.
    test "refuses a back request the moves did not offer, without calling the host" do
      socket = mount_journey()
      refute html(socket) =~ ~s(data-riddler-back)

      refused = event(socket, "back", %{"screen" => "patron_details", "back" => true})

      refute_received {:host, :back, _journey, _request}
      assert refused.assigns == socket.assigns
    end

    test "refuses a back request for another screen or of another shape" do
      socket = mount_journey() |> event("submit", form("details_submitted", @filled))

      for params <- [
            %{"screen" => "patron_details", "back" => true},
            %{"screen" => "card_pickup", "back" => "true"},
            %{"screen" => "card_pickup", "back" => true, "outcome" => "pickup_confirmed"},
            %{"back" => true}
          ] do
        refused = event(socket, "back", params)

        refute_received {:host, :back, _journey, _request}
        assert refused.assigns == socket.assigns
      end
    end
  end

  describe "waiting and done" do
    # Mutation: set no timer for a waiting answer's retry_after_ms - goes red.
    test "draws waiting and asks the host again after the hint" do
      set_status("J-1", {:waiting, %{"reason" => "card_number_pending", "retry_after_ms" => 5}})
      socket = mount_journey()
      html = html(socket)

      assert html =~ ~s(data-riddler-state="waiting")
      assert html =~ ~s(data-riddler-reason="card_number_pending")
      assert html =~ ~s(role="status")
      assert html =~ "One moment."

      assert_receive {:phoenix, :send_update,
                      {{Journey, "registration"}, %{id: "registration", refresh: true} = update}}

      set_status("J-1", :done)
      {:ok, socket} = Journey.update(update, socket)

      assert html(socket) =~ ~s(data-riddler-state="done")
      assert html(socket) =~ "All done."
    end

    # Mutation: set the timer only when the Journey is presented on mount - goes red.
    test "asks the host again after the hint when a submit lands in waiting" do
      socket = mount_journey() |> event("submit", form("details_submitted", @filled))
      params = %{"riddler-screen" => "card_pickup", "outcome" => "pickup_confirmed"}
      socket = event(socket, "submit", params)

      assert html(socket) =~ ~s(data-riddler-state="waiting")
      assert_receive {:phoenix, :send_update, {{Journey, "registration"}, %{refresh: true}}}
    end

    # Mutation: set a new timer without cancelling the pending one - goes red.
    test "cancels a pending timer before it sets the next" do
      set_status("J-1", {:waiting, %{"retry_after_ms" => 60_000}})
      socket = mount_journey()
      first = socket.assigns.retry
      assert is_integer(Process.read_timer(first))

      {:ok, socket} = Journey.update(%{id: "registration", refresh: true}, socket)

      assert Process.read_timer(first) == false
      assert is_integer(Process.read_timer(socket.assigns.retry))
    end

    test "sets no timer for waiting without a hint" do
      set_status("J-1", :waiting)
      html = mount_journey(%{waiting_text: "Your card is on its way."}) |> html()

      assert html =~ "Your card is on its way."
      refute_receive {:phoenix, :send_update, _update}, 20
    end

    test "draws done in the host's words, and not the result" do
      set_status("J-1", {:done, %{"card_number" => "EXAMPLE-CARD-0001"}})
      html = mount_journey(%{done_text: "Your card is ready."}) |> html()

      assert html =~ ~s(data-riddler-done)
      assert html =~ "Your card is ready."
      refute html =~ "EXAMPLE-CARD-0001"
    end
  end

  describe "the access check" do
    # Mutation: draw the visitor's refusal for a missing access module - goes red.
    test "raises ArgumentError at mount without an access module, and draws no refusal" do
      socket = %Socket{assigns: %{__changed__: %{}, myself: %CID{cid: 1}}, transport_pid: self()}
      {:ok, socket} = Journey.mount(socket)
      base = %{id: "registration", journey: "J-1", host: RegistrationHost, actor: "P-1001"}

      for access <- [nil, RegistrationHost, "PatronAccess", Library.NoSuchAccess] do
        assigns = if access, do: Map.put(base, :access, access), else: base

        assert_raise ArgumentError, ~r/:access/, fn -> Journey.update(assigns, socket) end
      end

      refute_received {:host, :present, _journey}
    end

    # Mutation: answer :ok for :present without asking - goes red.
    test "asks with :present on mount and draws the refusal for an actor not a member" do
      socket = mount_journey()
      assert_received {:access, :present}
      assert html(socket) =~ ~s(data-riddler-screen="patron_details")

      socket = mount_journey(%{actor: "P-2002"})
      html = html(socket)

      assert html =~ ~s(data-riddler-refused)
      assert html =~ "There is nothing to show here."
      refute html =~ "<form"
      refute html =~ "data-riddler-state"
      refute html =~ "Get your library card"
      assert socket.assigns.answer == nil
    end

    # Mutation: draw a refusal that says whether the Journey exists - goes red.
    test "draws one refusal alike for a Journey the host does not have and one not the actor's" do
      unknown = mount_journey(%{journey: "J-404"}) |> html()
      forbidden = mount_journey(%{actor: "P-2002"}) |> html()

      assert unknown =~ ~s(data-riddler-refused)
      assert unknown == forbidden

      held = mount_journey(%{journey: "J-404", refused_text: "Not here."}) |> html()
      assert held =~ "Not here."
    end

    # Mutation: check access at mount only - goes red.
    test "refuses a submit once the membership is revoked after the mount" do
      socket = mount_journey()
      assert_received {:access, :present}
      Process.put({:revoked, "P-1001"}, true)

      refused =
        event(
          socket,
          "submit",
          form(
            "details_submitted",
            Map.put(@filled, "riddler-password", %{"card_pin" => @sentinel})
          )
        )

      refute_received {:host, :submit, _journey, _submit}
      assert html(refused) =~ ~s(data-riddler-refused)
      refute html(refused) =~ "<form"
      refute inspect(refused.assigns, limit: :infinity, printable_limit: :infinity) =~ @sentinel

      again = event(refused, "submit", form("details_submitted", @filled))
      refute_received {:host, :submit, _journey, _submit}
      assert again.assigns == refused.assigns
    end

    # Mutation: check access at mount only - goes red.
    test "refuses a back request once the membership is revoked after the mount" do
      socket = mount_journey() |> event("submit", form("details_submitted", @filled))
      assert_received {:host, :submit, "J-1", _submit}
      Process.put({:revoked, "P-1001"}, true)

      refused = event(socket, "back", %{"screen" => "card_pickup", "back" => true})

      refute_received {:host, :back, _journey, _request}
      assert html(refused) =~ ~s(data-riddler-refused)
      refute html(refused) =~ "<form"
    end

    # Mutation: ask the access check with :present for every operation - goes red.
    test "asks with :submit before every submit and :back before every back" do
      socket = mount_journey()
      assert_received {:access, :present}

      socket = event(socket, "submit", form("details_submitted", @filled))
      assert_received {:access, :submit}
      refute_received {:access, :present}

      event(socket, "back", %{"screen" => "card_pickup", "back" => true})
      assert_received {:access, :back}
    end

    # Mutation: skip the access check while an answer is drawn - goes red.
    test "asks again on a refresh, and refuses once the membership is revoked" do
      socket = mount_journey()
      Process.put({:revoked, "P-1001"}, true)

      {:ok, socket} = Journey.update(%{id: "registration", refresh: true}, socket)

      assert html(socket) =~ ~s(data-riddler-refused)
      refute html(socket) =~ "<form"
    end

    # Mutation: re-present on a changed journey only - goes red.
    test "an actor changed after the mount is refused, and a changed host is asked again" do
      socket = mount_journey()
      assert_received {:host, :present, "J-1"}

      {:ok, refused} = Journey.update(%{id: "registration", actor: "P-2002"}, socket)

      assert_received {:host, :present, "J-1"}
      assert html(refused) =~ ~s(data-riddler-refused)
      refute html(refused) =~ "<form"

      {:ok, _socket} = Journey.update(%{id: "registration", host: RegistrationHost}, socket)
      refute_received {:host, :present, _journey}

      Process.put({:revoked, "P-1001"}, true)
      {:ok, moved} = Journey.update(%{id: "registration", access: PatronAccess.Other}, socket)
      assert_received {:host, :present, "J-1"}
      assert html(moved) =~ ~s(data-riddler-refused)
    end
  end

  describe "a host outside its contract" do
    # Mutation: log the exception's message - goes red.
    test "keeps what is drawn when submit/2 raises, throws or exits, and logs no parameter" do
      socket = mount_journey()
      fields = Map.put(@filled, "riddler-password", %{"card_pin" => @sentinel})

      for how <- [:raise, :throw, :exit] do
        Process.put({:misbehave, :submit}, how)

        log =
          capture_log(fn ->
            kept = event(socket, "submit", form("details_submitted", fields))
            assert kept.assigns == socket.assigns
          end)

        assert log =~ "RiddlerLiveView.Journey: the host's submit/2"
        refute log =~ @sentinel
        refute log =~ "4321"
      end
    end

    # Mutation: draw the refusal on an answer outside the contract - goes red.
    test "keeps what is drawn when submit/2 or back/2 answers outside the contract" do
      socket = mount_journey()

      for answer <- [{:error, :timeout}, :ok, {:ok, "screen"}, {:error, [:not_a_finding]}] do
        Process.put({:misbehave, :submit}, {:answer, answer})

        log =
          capture_log(fn ->
            kept = event(socket, "submit", form("details_submitted", @filled))
            assert kept.assigns == socket.assigns
          end)

        assert log =~ "the host's submit/2 answered outside its contract"
      end

      Process.delete({:misbehave, :submit})
      socket = event(socket, "submit", form("details_submitted", @filled))
      Process.put({:misbehave, :back}, {:answer, {:error, :timeout}})

      capture_log(fn ->
        kept = event(socket, "back", %{"screen" => "card_pickup", "back" => true})
        assert kept.assigns == socket.assigns
      end)
    end

    # Mutation: keep what is drawn on a present/1 outside the contract - goes red.
    test "draws the refusal when present/1 raises or answers outside the contract" do
      for misbehave <- [:raise, :exit, {:answer, {:error, :timeout}}, {:answer, {:ok, "screen"}}] do
        Process.put({:misbehave, :present}, misbehave)

        capture_log(fn ->
          html = mount_journey() |> html()
          assert html =~ ~s(data-riddler-refused)
          refute html =~ "<form"
        end)
      end
    end

    # Mutation: answer :ok when the access check raises - goes red.
    test "draws the refusal when the access module raises, on mount and on a submit" do
      socket = mount_journey()
      Process.put({:misbehave, :access}, :raise)

      log =
        capture_log(fn ->
          refused = event(socket, "submit", form("details_submitted", @filled))
          refute_received {:host, :submit, _journey, _submit}
          assert html(refused) =~ ~s(data-riddler-refused)

          assert mount_journey() |> html() =~ ~s(data-riddler-refused)
        end)

      assert log =~ "the access check raised ArgumentError"
      refute log =~ "P-1001"
    end

    # Mutation: answer true from shaped?/1 for every answer - goes red.
    test "draws the refusal when present/1 answers a screen of a shape riddler never presents" do
      {:ok, scope} = Scope.new("patron", "P-1001")

      for answer <- [
            %{"state" => "screen", "screen" => "oops", "moves" => %{}},
            %{"state" => "screen", "screen" => 7, "moves" => %{}},
            %{"state" => "screen", "screen" => %{"key" => "patron_details", "elements" => []}},
            %{
              "state" => "screen",
              "screen" => %{"key" => "k", "elements" => [7]},
              "moves" => %{}
            },
            %{"state" => "elsewhere"}
          ] do
        Process.put({:misbehave, :present}, {:answer, {:ok, scope, answer}})

        log =
          capture_log(fn ->
            html = mount_journey() |> html()
            assert html =~ ~s(data-riddler-refused)
            refute html =~ "<form"
          end)

        assert log =~ "the host's present/1 answered outside its contract"
      end
    end

    # Mutation: answer true from shaped?/1 for every answer - goes red.
    test "keeps what is drawn when submit/2 answers a screen of a shape riddler never presents" do
      socket = mount_journey()

      for answer <- [
            %{"state" => "screen", "screen" => "oops"},
            %{"state" => "screen", "screen" => 7, "moves" => %{}},
            %{"state" => "screen", "screen" => %{"key" => "k", "elements" => "x"}, "moves" => %{}}
          ] do
        Process.put({:misbehave, :submit}, {:answer, {:ok, answer}})

        log =
          capture_log(fn ->
            kept = event(socket, "submit", form("details_submitted", @filled))
            assert kept.assigns == socket.assigns
          end)

        assert log =~ "the host's submit/2 answered outside its contract"
      end
    end

    # Mutation: skip the render probe in drawable/3 - goes red.
    test "keeps what is drawn, or refuses, when an answer of riddler's shape does not render" do
      {:ok, scope} = Scope.new("patron", "P-1001")
      waiting = %{"state" => "waiting", "reason" => %{"not" => "a string"}}
      socket = mount_journey()

      for answer <- [{:ok, waiting}, {:error, [%{"code" => %{}, "element_key" => nil}]}] do
        Process.put({:misbehave, :submit}, {:answer, answer})

        log =
          capture_log(fn ->
            kept = event(socket, "submit", form("details_submitted", @filled))
            assert kept.assigns == socket.assigns
            assert html(kept) =~ ~s(data-riddler-screen="patron_details")
          end)

        assert log =~ "the host's submit/2 raised"
      end

      Process.put({:misbehave, :present}, {:answer, {:ok, scope, waiting}})

      capture_log(fn ->
        assert mount_journey() |> html() =~ ~s(data-riddler-refused)
      end)
    end

    # Mutation: accept any retry_after_ms in shaped?/1 - goes red.
    test "refuses, or keeps what is drawn, for a waiting answer whose retry_after_ms riddler never gives" do
      socket = mount_journey()

      for ms <- [-1, "5", 1.5] do
        waiting = %{"state" => "waiting", "retry_after_ms" => ms}
        Process.put({:misbehave, :submit}, {:answer, {:ok, waiting}})

        log =
          capture_log(fn ->
            kept =
              try do
                event(socket, "submit", form("details_submitted", @filled))
              rescue
                exception -> exception
              end

            assert %Socket{} = kept
            assert kept.assigns == socket.assigns
          end)

        assert log =~ "the host's submit/2 answered outside its contract"

        set_status("J-1", {:screen, "patron_details"})
        {:ok, scope} = Scope.new("patron", "P-1001")
        Process.put({:misbehave, :present}, {:answer, {:ok, scope, waiting}})

        capture_log(fn ->
          mounted =
            try do
              mount_journey()
            rescue
              exception -> exception
            end

          assert %Socket{} = mounted
          assert html(mounted) =~ ~s(data-riddler-refused)
        end)

        Process.delete({:misbehave, :present})
      end
    end

    # Mutation: hand retry_after_ms to the timer uncapped - goes red.
    test "waits at most the component's ceiling for a longer retry_after_ms" do
      set_status("J-1", {:waiting, %{"retry_after_ms" => 4_294_967_296}})

      mounted =
        try do
          mount_journey()
        rescue
          exception -> exception
        end

      assert %Socket{} = mounted
      assert html(mounted) =~ ~s(data-riddler-state="waiting")
      assert Process.read_timer(mounted.assigns.retry) in 4_294_967_000..4_294_967_295
      Process.cancel_timer(mounted.assigns.retry)
    end
  end

  describe "a datetime question in the visitor's time zone" do
    # A branch library's pickup appointment: a bounded datetime question,
    # 09:00 to 18:00 in Denver on 2026-11-27, and an unbounded reminder.
    @pickup %{
      "schema_version" => 2,
      "id" => "card_pickup_booking",
      "screens" => [
        %{
          "key" => "pickup_booking",
          "title" => "Book your card pickup",
          "elements" => [
            %{
              "type" => "text_question",
              "key" => "pickup_at",
              "label" => "Preferred pickup appointment",
              "required" => true,
              "format" => "datetime",
              "min" => "2026-11-27T16:00Z",
              "max" => "2026-11-28T01:00Z"
            },
            %{
              "type" => "text_question",
              "key" => "remind_at",
              "label" => "Remind me at",
              "format" => "datetime"
            },
            %{
              "type" => "text_question",
              "key" => "pickup_note",
              "label" => "Anything the desk should know?"
            },
            %{
              "type" => "choice_question",
              "key" => "pickup_branch",
              "label" => "Which branch?",
              "answer_options" => [
                %{"value" => "2026-11-27T10:00", "label" => "Riverside"},
                %{"value" => "central", "label" => "Central"}
              ]
            },
            %{
              "type" => "button",
              "key" => "booking_next",
              "label" => "Book",
              "outcome" => "pickup_booked"
            }
          ]
        }
      ]
    }

    defp mount_booking(zone) do
      put_engine("J-7", %{
        document: Document.admit(@pickup),
        status: {:screen, "pickup_booking"},
        root: %{}
      })

      mount_journey(%{journey: "J-7", time_zone: zone})
    end

    defp book(socket, fields) do
      params =
        Map.merge(%{"riddler-screen" => "pickup_booking", "outcome" => "pickup_booked"}, fields)

      socket = event(socket, "submit", params)
      assert_received {:host, :submit, "J-7", %{"responses" => responses}}
      {socket, responses}
    end

    defp held(key), do: get_in(engine("J-7"), [:root, "responses", key])

    # Mutation: hand on the browser's wall time unchanged, no offset added - goes red.
    test "adds the visitor's offset to the wall time, and riddler validates the instant" do
      {socket, responses} =
        mount_booking("America/Denver") |> book(%{"pickup_at" => "2026-11-27T10:00"})

      assert responses["pickup_at"] == "2026-11-27T10:00-07:00"
      assert socket.assigns.findings == []
      assert held("pickup_at") == "2026-11-27T10:00-07:00"
    end

    # Mutation: read every wall time in standard time, whatever the date - goes red.
    test "adds the offset the zone keeps at the submitted moment, Z where it is zero" do
      for {zone, wall, written} <- [
            {"America/Denver", "2026-07-04T14:30:15", "2026-07-04T14:30:15-06:00"},
            {"Asia/Kolkata", "2026-11-27T21:00", "2026-11-27T21:00+05:30"},
            {"Etc/UTC", "2026-11-27T16:00", "2026-11-27T16:00Z"}
          ] do
        {_socket, responses} =
          mount_booking(zone)
          |> book(%{"pickup_at" => "2026-11-27T17:00:00", "remind_at" => wall})

        assert responses["remind_at"] == written
      end
    end

    # Mutation: convert the bounds or the wall time with the wrong sign of the offset - goes red.
    test "holds the visitor to the presented min and max, read in their zone" do
      for {wall, verdict} <- [
            {"2026-11-27T08:59", :refused},
            {"2026-11-27T09:00", :held},
            {"2026-11-27T18:00", :held},
            {"2026-11-27T18:01", :refused}
          ] do
        {socket, _responses} = mount_booking("America/Denver") |> book(%{"pickup_at" => wall})

        case verdict do
          :held ->
            assert socket.assigns.findings == []

          :refused ->
            assert [%{"element_key" => "pickup_at", "code" => "response.out_of_range"}] =
                     Enum.map(
                       socket.assigns.findings,
                       &%{"element_key" => &1.element_key, "code" => &1.code}
                     )
        end
      end
    end

    # Mutation: read a skipped wall time with the offset after the gap - goes red.
    test "reads a wall time the clocks skip with the offset in force before the change" do
      {_socket, responses} =
        mount_booking("America/Denver")
        |> book(%{"pickup_at" => "2026-11-27T10:00", "remind_at" => "2026-03-08T02:30"})

      assert responses["remind_at"] == "2026-03-08T02:30-07:00"
    end

    # Mutation: read a wall time the clocks pass twice with the second offset - goes red.
    test "reads a wall time the clocks pass twice as the earlier instant" do
      {_socket, responses} =
        mount_booking("America/Denver")
        |> book(%{"pickup_at" => "2026-11-27T10:00", "remind_at" => "2026-11-01T01:30"})

      assert responses["remind_at"] == "2026-11-01T01:30-06:00"
    end

    # Mutation: add an offset to every value under a datetime question's key - goes red.
    test "hands on unchanged what is not a wall time, and everything with no zone" do
      for {zone, value} <- [
            {"America/Denver", ""},
            {"America/Denver", "2026-11-27T10:00-07:00"},
            {"America/Denver", "2026-11-27T10:00:00.500"},
            {"America/Denver", "2026-02-30T10:00"},
            {"America/Denver", "next Friday"},
            {nil, "2026-11-27T10:00"},
            {"Mars/Olympus_Mons", "2026-11-27T10:00"}
          ] do
        {_socket, responses} =
          mount_booking(zone) |> book(%{"pickup_at" => "2026-11-27T17:00Z", "remind_at" => value})

        assert responses["remind_at"] == value
      end
    end

    # Mutation: add the offset to every response on a screen with a datetime question - goes red.
    test "adds no offset to a response of any question but a datetime one" do
      {_socket, responses} =
        mount_booking("America/Denver")
        |> book(%{
          "pickup_at" => "2026-11-27T10:00",
          "pickup_note" => "2026-11-27T10:00",
          "pickup_branch" => "2026-11-27T10:00"
        })

      assert responses["pickup_at"] == "2026-11-27T10:00-07:00"
      assert responses["pickup_note"] == "2026-11-27T10:00"
      assert responses["pickup_branch"] == "2026-11-27T10:00"
    end

    # Mutation: leave time_zone out of the assigns passed to the components - goes red.
    test "draws the datetime question as a datetime-local input in the visitor's zone" do
      html = mount_booking("America/Denver") |> html()

      assert html =~
               ~r/<input type="datetime-local" id="registration-element-pickup_at"[^>]* min="2026-11-27T09:00" max="2026-11-27T18:00"/

      refute mount_booking(nil) |> html() =~ "datetime-local"
    end
  end
end
