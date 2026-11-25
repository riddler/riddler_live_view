defmodule RiddlerLiveView.ElementsTest do
  @moduledoc """
  The component that draws a screen's elements: each known kind through its
  own component, a host's kinds through the component map, and an element of
  a kind nothing draws not at all, with the screen's submit blocked.
  """

  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias RiddlerLiveView.Components

  @moves %{"outcomes" => ["details_submitted", "card_type_changed"], "back" => true}

  @heading %{"type" => "heading", "key" => "details_heading", "level" => 2, "text" => "Details"}
  @text %{"type" => "text", "key" => "address_note", "text" => "Your address."}
  @email %{"type" => "text_question", "key" => "reminder_email", "label" => "Email"}
  @pin %{"type" => "secret_question", "key" => "card_pin", "label" => "PIN", "held" => true}
  @card_type %{
    "type" => "choice_question",
    "key" => "card_type",
    "label" => "Card",
    "select" => "one",
    "answer_options" => [%{"value" => "adult", "label" => "Adult card"}]
  }
  @rules %{"type" => "boolean_question", "key" => "agrees_to_rules", "label" => "I agree."}
  @continue %{
    "type" => "button",
    "key" => "details_continue",
    "label" => "Continue",
    "outcome" => "details_submitted"
  }
  @change %{
    "type" => "button",
    "key" => "details_change",
    "label" => "Change card type",
    "outcome" => "card_type_changed",
    "validates" => false
  }
  @rating %{"type" => "rating_question", "key" => "visit_rating", "label" => "Rate us"}

  defp screen(elements), do: %{"key" => "details", "title" => "Details", "elements" => elements}

  defp elements_html(elements, opts \\ []) do
    assigns = %{
      screen: screen(elements),
      moves: @moves,
      components: Keyword.get(opts, :components, %{}),
      findings: Keyword.get(opts, :findings, []),
      finding_text: Keyword.get(opts, :finding_text, %{}),
      unknown_text: Keyword.get(opts, :unknown_text)
    }

    if assigns.unknown_text do
      rendered_to_string(~H"""
      <Components.elements
        screen={@screen}
        moves={@moves}
        components={@components}
        findings={@findings}
        finding_text={@finding_text}
        unknown_text={@unknown_text}
      />
      """)
    else
      rendered_to_string(~H"""
      <Components.elements
        screen={@screen}
        moves={@moves}
        components={@components}
        findings={@findings}
        finding_text={@finding_text}
      />
      """)
    end
  end

  defp kinds_drawn(html) do
    ~r/\sdata-riddler-element="([^"]+)"/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
  end

  defp branch_map(assigns) do
    ~H"""
    <p class="branch-map" data-riddler-element="branch_map" data-riddler-key={@element["key"]}>
      {@element["label"]} {length(@findings)} {@blocked_by || "open"} {Enum.join(
        @moves["outcomes"],
        ","
      )}
    </p>
    """
  end

  describe "elements/1 with the kinds the package draws" do
    # Mutation: drop the button clause from the private element component - goes red.
    test "draws every element through the component for its kind, in the screen's order" do
      html = elements_html([@heading, @text, @email, @pin, @card_type, @rules, @continue])

      assert kinds_drawn(html) ==
               ~w(heading text text_question secret_question choice_question boolean_question button)
    end

    # Mutation: always pass a notice id to the buttons - goes red.
    test "draws no notice and leaves the buttons enabled when every element is drawn" do
      html = elements_html([@email, @continue])

      refute html =~ "data-riddler-unknown"
      refute html =~ "disabled"
      refute html =~ "data-riddler-blocked"
    end

    # Mutation: stop passing findings to the question components - goes red.
    test "passes findings and finding_text to every question" do
      findings = [
        %{"code" => "response.required", "element_key" => "reminder_email"},
        %{"code" => "response.required", "element_key" => "card_type"}
      ]

      html =
        elements_html([@email, @card_type],
          findings: findings,
          finding_text: %{"response.required" => "Fill this in, please."}
        )

      assert html =~ ~s(id="riddler-element-reminder_email-finding-1")
      assert html =~ ~s(id="riddler-element-card_type-finding-1")
      assert length(Regex.scan(~r/Fill this in, please\./, html)) == 2
    end

    # Mutation: pass moves as nil to the button component - goes red.
    test "draws a button only where the moves list its outcome" do
      html =
        elements_html([@continue, %{@change | "outcome" => "not_offered", "key" => "other"}])

      assert kinds_drawn(html) == ["button"]
      assert html =~ ~s(data-riddler-key="details_continue")
    end
  end

  describe "elements/1 with an element of a kind nothing draws" do
    # Mutation: draw the unknown element as a text paragraph - goes red.
    test "does not draw the element and draws the notice above the elements" do
      html = elements_html([@heading, @rating, @continue])

      assert kinds_drawn(html) == ["heading", "button"]
      refute html =~ "Rate us"
      refute html =~ "visit_rating"

      assert html =~
               ~r{\A\s*<p id="riddler-screen-details-unknown" role="status" class="riddler-unknown" data-riddler-unknown="rating_question">\s*Part of this screen cannot be shown here, so it cannot be sent\.\s*</p>}
    end

    # Mutation: pass blocked_by={nil} from the dispatcher to the buttons - goes red.
    test "draws every button disabled, naming the notice" do
      html = elements_html([@rating, @continue, @change])

      buttons = Regex.scan(~r/<button\b[^>]*>/, html) |> List.flatten()
      assert length(buttons) == 2

      for button <- buttons do
        assert button =~ ~r/\sdisabled[\s>]/
        assert button =~ ~s(aria-describedby="riddler-screen-details-unknown")
        assert button =~ ~s(data-riddler-blocked="riddler-screen-details-unknown")
      end
    end

    # Mutation: ignore @unknown_text and always draw the package's sentence - goes red.
    test "draws the host's notice text in place of the package's" do
      html = elements_html([@rating], unknown_text: "Finish this at the front desk.")

      assert html =~ "Finish this at the front desk."
      refute html =~ "Part of this screen"
    end

    # Mutation: drop the blank-text fallback for unknown_text - goes red.
    test "falls back to the package's sentence for blank notice text" do
      html = elements_html([@rating], unknown_text: "  ")

      assert html =~ "Part of this screen cannot be shown here, so it cannot be sent."
    end

    # Mutation: keep non-string kinds in the notice's data attribute - goes red.
    test "names each unknown kind once, and an element with no string type blocks too" do
      html =
        elements_html([@rating, %{"key" => "untyped"}, %{@rating | "key" => "again"}, @continue])

      assert html =~ ~s(data-riddler-unknown="rating_question")
      assert html =~ ~r/<button\b[^>]*\sdisabled/

      only_untyped = elements_html([%{"key" => "untyped", "type" => 7}, @continue])
      assert only_untyped =~ ~s(data-riddler-unknown="")
      assert only_untyped =~ ~r/<button\b[^>]*\sdisabled/
    end
  end

  describe "elements/1 with a component map" do
    # Mutation: treat a mapped kind as unknown in the drawer - goes red.
    test "draws a host's kind through the host's component, with the screen's assigns" do
      findings = [%{"code" => "response.required", "element_key" => "pickup_branch"}]

      html =
        elements_html(
          [%{"type" => "branch_map", "key" => "pickup_branch", "label" => "Branch"}, @continue],
          components: %{"branch_map" => &branch_map/1},
          findings: findings
        )

      assert kinds_drawn(html) == ["branch_map", "button"]

      assert html =~
               ~r{data-riddler-key="pickup_branch">\s*Branch 1 open details_submitted,card_type_changed\s*</p>}

      refute html =~ "data-riddler-unknown"
      refute html =~ "disabled"
    end

    # Mutation: hand the host's component a nil blocked_by - goes red.
    test "hands the host's component the notice id when the screen is blocked" do
      html =
        elements_html(
          [%{"type" => "branch_map", "key" => "pickup_branch", "label" => "Branch"}, @rating],
          components: %{"branch_map" => &branch_map/1}
        )

      assert html =~ "Branch 0 riddler-screen-details-unknown"
    end

    # Mutation: let a mapped known kind through the component map check - goes red.
    test "refuses a component map that names a kind the package draws" do
      assert_raise ArgumentError, ~r/names "text_question", a kind this package draws/, fn ->
        elements_html([@email], components: %{"text_question" => &branch_map/1})
      end
    end

    # Mutation: accept any value in the component map - goes red.
    test "refuses a component map entry that is not a function component" do
      for components <- [%{"branch_map" => :not_a_function}, %{branch_map: &branch_map/1}] do
        assert_raise ArgumentError, ~r/a component map entry is an element type/, fn ->
          elements_html([@text], components: components)
        end
      end
    end
  end

  describe "elements/1, what it hands on" do
    # Mutation: drop List.wrap(@class) from the notice's class - goes red.
    test "adds the host's classes to the notice's own" do
      assigns = %{screen: screen([@rating]), moves: @moves}

      html =
        rendered_to_string(
          ~H|<Components.elements screen={@screen} moves={@moves} class="desk-notice" />|
        )

      assert html =~ ~s(class="riddler-unknown desk-notice")
    end

    # Mutation: hand the host's component an empty finding_text - goes red.
    test "hands the host's component finding_text" do
      show_text = fn assigns ->
        ~H"""
        <p class="branch-map" data-riddler-element="branch_map">{@finding_text["x.code"]}</p>
        """
      end

      html =
        elements_html([%{"type" => "branch_map", "key" => "pickup_branch"}],
          components: %{"branch_map" => show_text},
          finding_text: %{"x.code" => "Pick a branch."}
        )

      assert html =~ "Pick a branch."
    end
  end

  describe "unknown_kinds/2" do
    # Mutation: answer a non-map element's kind as the element itself - goes red.
    test "answers nil for an element that is not a map" do
      assert Components.unknown_kinds(screen(["x", nil, @text])) == [nil]
    end

    # Mutation: drop Enum.uniq/1 - goes red.
    test "answers each kind nothing draws once, in the screen's order" do
      screen =
        screen([@rating, @text, %{"type" => "map_pin"}, %{@rating | "key" => "again"}, %{}])

      assert Components.unknown_kinds(screen) == ["rating_question", "map_pin", nil]
    end

    # Mutation: ignore the component map in unknown_kinds/2 - goes red.
    test "answers no kind the component map draws" do
      screen = screen([@rating, %{"type" => "map_pin"}])

      assert Components.unknown_kinds(screen, %{"map_pin" => &branch_map/1}) == [
               "rating_question"
             ]
    end

    # Mutation: answer every element's kind - goes red.
    test "answers [] for a screen whose elements are all drawn, and for one with none" do
      assert Components.unknown_kinds(screen([@heading, @email, @continue])) == []
      assert Components.unknown_kinds(%{"key" => "done"}) == []
    end

    # Mutation: drop the check for a map that is not a map - goes red.
    test "refuses a component map that is not a map" do
      assert_raise ArgumentError, ~r/the component map is a map/, fn ->
        Components.unknown_kinds(screen([]), [{"map_pin", &branch_map/1}])
      end
    end
  end

  describe "button/1 with blocked_by" do
    # Mutation: drop disabled={...} from the button - goes red.
    test "draws the button disabled and names the notice" do
      assigns = %{element: @continue, moves: @moves}

      html =
        rendered_to_string(
          ~H|<Components.button element={@element} moves={@moves} blocked_by="why" />|
        )

      assert html =~
               ~r/<button type="submit" name="outcome" value="details_submitted" disabled aria-describedby="why" data-riddler-blocked="why"/
    end
  end
end
