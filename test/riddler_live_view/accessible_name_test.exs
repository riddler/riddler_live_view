defmodule RiddlerLiveView.AccessibleNameTest do
  @moduledoc """
  The accessible label and description riddler presents on any element:
  `"accessible_label"` drawn as the `aria-label` of the element's accessible
  node, and `"accessible_description"` as a hidden text node that node names
  last in its `aria-describedby`. An element that carries neither, or only
  blank ones, draws the markup it drew before either existed.
  """

  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias Riddler.Screens.Document
  alias RiddlerLiveView.Components

  @moves %{"outcomes" => ["details_submitted"], "back" => false}

  @options [%{"value" => "adult", "label" => "Adult"}, %{"value" => "child", "label" => "Child"}]

  @elements %{
    "heading" => %{
      "type" => "heading",
      "key" => "details_heading",
      "level" => 2,
      "text" => "Your details"
    },
    "text" => %{
      "type" => "text",
      "key" => "reminder_note",
      "text" => "We send due-date reminders to this address."
    },
    "image" => %{
      "type" => "image",
      "key" => "branch_photo",
      "src" => "/images/riverside.png",
      "alt" => "The Riverside branch"
    },
    "divider" => %{"type" => "divider", "key" => "details_rule"},
    "link" => %{
      "type" => "link",
      "key" => "lending_rules",
      "label" => "Read the lending rules",
      "href" => "/lending-rules"
    },
    "text_question" => %{
      "type" => "text_question",
      "key" => "reminder_email",
      "label" => "Email",
      "help" => "One reminder a week.",
      "required" => true
    },
    "secret_question" => %{
      "type" => "secret_question",
      "key" => "card_pin",
      "label" => "Card PIN",
      "held" => true,
      "help" => "Four digits."
    },
    "choice_question" => %{
      "type" => "choice_question",
      "key" => "card_type",
      "label" => "Card",
      "select" => "one",
      "help" => "Change it at the desk.",
      "answer_options" => @options
    },
    "choice_question dropdown" => %{
      "type" => "choice_question",
      "key" => "card_type",
      "label" => "Card",
      "select" => "one",
      "style" => "dropdown",
      "answer_options" => @options
    },
    "boolean_question" => %{
      "type" => "boolean_question",
      "key" => "agrees_to_rules",
      "label" => "I agree to the lending rules",
      "help" => "Twelve items at a time."
    },
    "button" => %{
      "type" => "button",
      "key" => "details_continue",
      "label" => "Continue",
      "outcome" => "details_submitted"
    }
  }

  # Each component's markup for the element above, drawn through elements/1
  # before the accessible label and description were drawn.
  @before [
    {"heading",
     "\n<h2 class=\"riddler-heading\" data-riddler-key=\"details_heading\" data-riddler-element=\"heading\">\n  Your details\n</h2>\n\n\n\n\n\n\n\n\n\n"},
    {"text",
     "\n\n<p class=\"riddler-text riddler-text-body\" data-riddler-element=\"text\" data-riddler-key=\"reminder_note\">\n  We send due-date reminders to this address.\n</p>\n\n\n\n\n\n\n\n\n"},
    {"image",
     "\n\n\n<img src=\"/images/riverside.png\" alt=\"The Riverside branch\" class=\"riddler-image\" data-riddler-element=\"image\" data-riddler-key=\"branch_photo\">\n\n\n\n\n\n\n\n"},
    {"divider",
     "\n\n\n\n<hr class=\"riddler-divider\" data-riddler-element=\"divider\" data-riddler-key=\"details_rule\">\n\n\n\n\n\n\n"},
    {"link",
     "\n\n\n\n\n<a href=\"/lending-rules\" class=\"riddler-link\" data-riddler-element=\"link\" data-riddler-key=\"lending_rules\">\n  Read the lending rules\n</a>\n\n\n\n\n\n"},
    {"text_question",
     "\n\n\n\n\n\n<div class=\"riddler-text-question\" data-riddler-element=\"text_question\" data-riddler-key=\"reminder_email\">\n  <label for=\"riddler-element-reminder_email\" class=\"riddler-label\" data-riddler-label>Email</label>\n  \n  <input type=\"text\" id=\"riddler-element-reminder_email\" name=\"reminder_email\" required aria-describedby=\"riddler-element-reminder_email-help\" class=\"riddler-input\" data-riddler-input>\n  \n  <p id=\"riddler-element-reminder_email-help\" class=\"riddler-help\" data-riddler-help>One reminder a week.</p>\n</div>\n\n\n\n\n"},
    {"secret_question",
     "\n\n\n\n\n\n\n<div class=\"riddler-secret-question\" data-riddler-element=\"secret_question\" data-riddler-key=\"card_pin\">\n  <label for=\"riddler-element-card_pin\" class=\"riddler-label\" data-riddler-label>Card PIN</label>\n  <input type=\"password\" id=\"riddler-element-card_pin\" name=\"riddler-password[card_pin]\" autocomplete=\"off\" aria-describedby=\"riddler-element-card_pin-held riddler-element-card_pin-help\" class=\"riddler-input\" data-riddler-input>\n  \n  <p id=\"riddler-element-card_pin-held\" class=\"riddler-held\" data-riddler-held>A value is held.</p>\n  <p id=\"riddler-element-card_pin-help\" class=\"riddler-help\" data-riddler-help>Four digits.</p>\n</div>\n\n\n\n"},
    {"choice_question",
     "\n\n\n\n\n\n\n\n<fieldset class=\"riddler-choice-question\" data-riddler-element=\"choice_question\" data-riddler-key=\"card_type\" data-riddler-select=\"one\" aria-describedby=\"riddler-element-card_type-help\">\n  <legend id=\"riddler-element-card_type-legend\" class=\"riddler-legend\" data-riddler-legend>Card</legend>\n  <div class=\"riddler-option\" data-riddler-option=\"adult\">\n    <input type=\"radio\" id=\"riddler-element-card_type-option-adult\" name=\"card_type\" value=\"adult\" class=\"riddler-input\" data-riddler-input>\n    <label for=\"riddler-element-card_type-option-adult\" class=\"riddler-label\" data-riddler-label>Adult</label>\n    \n  </div><div class=\"riddler-option\" data-riddler-option=\"child\">\n    <input type=\"radio\" id=\"riddler-element-card_type-option-child\" name=\"card_type\" value=\"child\" class=\"riddler-input\" data-riddler-input>\n    <label for=\"riddler-element-card_type-option-child\" class=\"riddler-label\" data-riddler-label>Child</label>\n    \n  </div>\n  \n  \n  \n  \n  \n  <p id=\"riddler-element-card_type-help\" class=\"riddler-help\" data-riddler-help>Change it at the desk.</p>\n</fieldset>\n\n\n"},
    {"choice_question dropdown",
     "\n\n\n\n\n\n\n\n<fieldset class=\"riddler-choice-question\" data-riddler-element=\"choice_question\" data-riddler-key=\"card_type\" data-riddler-select=\"one\" data-riddler-style=\"dropdown\">\n  <legend id=\"riddler-element-card_type-legend\" class=\"riddler-legend\" data-riddler-legend>Card</legend>\n  \n  \n  \n  <select id=\"riddler-element-card_type\" name=\"card_type\" aria-labelledby=\"riddler-element-card_type-legend\" class=\"riddler-select\" data-riddler-input>\n    <option value=\"\"></option>\n    <option value=\"adult\" class=\"riddler-option\" data-riddler-option=\"adult\">\n      Adult\n    </option><option value=\"child\" class=\"riddler-option\" data-riddler-option=\"child\">\n      Child\n    </option>\n  </select>\n  \n  \n  \n</fieldset>\n\n\n"},
    {"boolean_question",
     "\n\n\n\n\n\n\n\n\n<div class=\"riddler-boolean-question\" data-riddler-element=\"boolean_question\" data-riddler-key=\"agrees_to_rules\">\n  <input type=\"checkbox\" id=\"riddler-element-agrees_to_rules\" name=\"agrees_to_rules\" value=\"true\" aria-describedby=\"riddler-element-agrees_to_rules-help\" class=\"riddler-input\" data-riddler-input>\n  <label for=\"riddler-element-agrees_to_rules\" class=\"riddler-label\" data-riddler-label>I agree to the lending rules</label>\n  \n  <p id=\"riddler-element-agrees_to_rules-help\" class=\"riddler-help\" data-riddler-help>Twelve items at a time.</p>\n</div>\n\n"},
    {"button",
     "\n\n\n\n\n\n\n\n\n\n<button type=\"submit\" name=\"outcome\" value=\"details_submitted\" class=\"riddler-button\" data-riddler-element=\"button\" data-riddler-key=\"details_continue\" data-riddler-outcome=\"details_submitted\" data-riddler-validates=\"true\">\n  Continue\n</button>\n"}
  ]

  defp html(element, opts \\ []) do
    assigns = %{
      screen: %{"key" => "details", "elements" => [element]},
      moves: @moves,
      findings: Keyword.get(opts, :findings, []),
      id_prefix: Keyword.get(opts, :id_prefix, "riddler")
    }

    rendered_to_string(~H"""
    <Components.elements screen={@screen} moves={@moves} findings={@findings} id_prefix={@id_prefix} />
    """)
  end

  defp authored(name, fields), do: Map.merge(Map.fetch!(@elements, name), fields)

  # The attributes of every start tag of the given name, in order.
  defp tags(html, tag) do
    ~r/<#{tag}\b([^>]*)>/ |> Regex.scan(html, capture: :all_but_first) |> List.flatten()
  end

  defp attr_value(attrs, name) do
    case Regex.run(~r/\s#{name}="([^"]*)"/, attrs) do
      [_, value] -> value
      nil -> nil
    end
  end

  # A heading is drawn through Phoenix's dynamic_tag, which orders its
  # attributes by its own map, so its markup is compared with the attributes
  # of each start tag sorted.
  defp sorted_attributes(html) do
    Regex.replace(~r/<([a-z0-9]+)((?:\s[^>]*)?)>/, html, fn _, tag, attrs ->
      sorted = ~r/\s[^\s=]+(?:="[^"]*")?/ |> Regex.scan(attrs) |> List.flatten() |> Enum.sort()
      "<" <> tag <> Enum.join(sorted) <> ">"
    end)
  end

  describe "an element with no accessible label or description" do
    # Mutation: draw aria-label={@accessible.label || ""} on every component - goes red.
    test "draws the markup each component drew before, byte for byte" do
      for {name, before} <- @before do
        drawn = html(Map.fetch!(@elements, name))

        if name == "heading" do
          assert sorted_attributes(drawn) == sorted_attributes(before), name
        else
          assert drawn == before, "#{name} drew:\n#{drawn}"
        end
      end
    end

    # Mutation: read the accessible fields without present_text/1 - goes red.
    test "a blank label or description draws as none" do
      for {name, _before} <- @before, blank <- ["", "  "] do
        element = Map.fetch!(@elements, name)

        drawn =
          html(
            Map.merge(element, %{"accessible_label" => blank, "accessible_description" => blank})
          )

        assert drawn == html(element), name
        refute drawn =~ "aria-label=", name
        refute drawn =~ "accessible-description", name
      end
    end
  end

  describe "an authored accessible label" do
    @label_nodes [
      {"heading", "h2"},
      {"image", "img"},
      {"divider", "hr"},
      {"link", "a"},
      {"text_question", "input"},
      {"secret_question", "input"},
      {"choice_question", "fieldset"},
      {"boolean_question", "input"},
      {"button", "button"}
    ]

    # Mutation: draw the text question's aria-label on its wrapper div instead of its input - goes red.
    test "is the aria-label of the node a visitor reaches, and of no other" do
      for {name, tag} <- @label_nodes do
        drawn = html(authored(name, %{"accessible_label" => "Named #{name}"}))

        labelled = Enum.filter(tags(drawn, "[a-z0-9]+"), &(&1 =~ " aria-label="))
        on_node = Enum.filter(tags(drawn, tag), &(&1 =~ " aria-label="))

        assert length(labelled) == 1, "#{name} draws #{length(labelled)} aria-labels"
        assert on_node == labelled, "#{name} draws its aria-label off its #{tag}"
        assert attr_value(hd(on_node), "aria-label") == "Named #{name}"
      end
    end

    # Mutation: drop alt={@alt} from the image when it carries a label - goes red.
    test "leaves an image's alt as its alt, a decorative one included" do
      for alt <- ["The Riverside branch", ""] do
        drawn = html(authored("image", %{"alt" => alt, "accessible_label" => "The branch"}))
        [img] = tags(drawn, "img")

        assert attr_value(img, "alt") == alt
        assert attr_value(img, "aria-label") == "The branch"
      end
    end

    # Mutation: name the multiline text question's textarea with no aria-label - goes red.
    test "names a textarea, a range input and a date input" do
      for fields <- [
            %{"style" => "multiline"},
            %{"format" => "integer", "style" => "slider", "min" => 1, "max" => 12},
            %{"format" => "date"}
          ] do
        element =
          authored("text_question", Map.put(fields, "accessible_label", "How you would like it"))

        drawn = html(element)
        control = List.first(tags(drawn, "input") ++ tags(drawn, "textarea"))
        assert attr_value(control, "aria-label") == "How you would like it"
      end
    end

    # Mutation: keep aria-labelledby on the select when the question carries a label - goes red.
    test "names a choice question's select or search input in place of its legend" do
      for fields <- [%{"style" => "dropdown"}, %{"searchable" => true}] do
        drawn =
          html(authored("choice_question", Map.put(fields, "accessible_label", "Card type")))

        [fieldset] = tags(drawn, "fieldset")
        assert attr_value(fieldset, "aria-label") == "Card type"

        [control] =
          Enum.filter(
            tags(drawn, "(?:select|input)"),
            &(&1 =~ ~s(id="riddler-element-card_type"))
          )

        assert attr_value(control, "aria-label") == "Card type"
        assert attr_value(control, "aria-labelledby") == nil
      end
    end

    # Mutation: draw aria-label={@accessible.label} on the text's paragraph - goes red.
    test "is not drawn on a text, whose paragraph takes no name" do
      drawn = html(authored("text", %{"accessible_label" => "Reminders"}))

      refute drawn =~ "aria-label="
    end
  end

  describe "an authored accessible description" do
    @described [
      {"heading", "h2", "details_heading", []},
      {"text", "p", "reminder_note", []},
      {"image", "img", "branch_photo", []},
      {"divider", "hr", "details_rule", []},
      {"link", "a", "lending_rules", []},
      {"text_question", "input", "reminder_email", ["help"]},
      {"secret_question", "input", "card_pin", ["held", "help"]},
      {"choice_question", "fieldset", "card_type", ["help"]},
      {"choice_question dropdown", "select", "card_type", []},
      {"boolean_question", "input", "agrees_to_rules", ["help"]},
      {"button", "button", "details_continue", []}
    ]

    # Mutation: drop accessible.description_id from the text question's aria-describedby - goes red.
    test "is hidden text the element's node names last in its aria-describedby" do
      for {name, tag, key, before} <- @described do
        drawn = html(authored(name, %{"accessible_description" => "More about #{name}."}))
        id = "riddler-element-#{key}-accessible-description"

        assert drawn =~
                 ~s(<span id="#{id}" hidden class="riddler-accessible-description" data-riddler-accessible-description>More about #{name}.</span>),
               name

        [attrs | _] = Enum.filter(tags(drawn, tag), &(&1 =~ " aria-describedby="))
        expected = Enum.map(before, &"riddler-element-#{key}-#{&1}") ++ [id]
        assert attr_value(attrs, "aria-describedby") == Enum.join(expected, " "), name
      end
    end

    # Mutation: name the description ahead of the findings in the text question's input - goes red.
    test "comes after a question's findings and help" do
      element = authored("text_question", %{"accessible_description" => "We write weekly."})

      drawn =
        html(element,
          findings: [%{"code" => "response.format", "element_key" => "reminder_email"}]
        )

      [input] = tags(drawn, "input")

      assert attr_value(input, "aria-describedby") ==
               "riddler-element-reminder_email-finding-1 riddler-element-reminder_email-help riddler-element-reminder_email-accessible-description"
    end

    # Mutation: name only the blocking notice in the button's aria-describedby - goes red.
    test "comes after the notice that blocks a button" do
      assigns = %{
        screen: %{
          "key" => "details",
          "elements" => [
            %{"type" => "rating_question", "key" => "visit_rating"},
            authored("button", %{"accessible_description" => "Sends the form."})
          ]
        },
        moves: @moves
      }

      drawn = rendered_to_string(~H"<Components.elements screen={@screen} moves={@moves} />")
      [button] = tags(drawn, "button")

      assert attr_value(button, "aria-describedby") ==
               "riddler-screen-details-unknown riddler-element-details_continue-accessible-description"
    end

    # Mutation: name the help only from the fieldset of a choice question drawn as a select - goes red.
    test "a select or a search input names the question's help and description too" do
      for fields <- [%{"style" => "dropdown"}, %{"searchable" => true}] do
        element =
          authored(
            "choice_question",
            Map.merge(fields, %{"accessible_description" => "Adult or child."})
          )

        [control] =
          Enum.filter(
            tags(html(element), "(?:select|input)"),
            &(&1 =~ ~s(id="riddler-element-card_type"))
          )

        assert attr_value(control, "aria-describedby") ==
                 "riddler-element-card_type-help riddler-element-card_type-accessible-description"
      end
    end

    # Mutation: drop id_prefix={@id_prefix} from the divider's call in elements/1 - goes red.
    test "takes its id from the id_prefix elements/1 passes each display kind and a button" do
      for {name, tag, key} <- [
            {"heading", "h2", "details_heading"},
            {"text", "p", "reminder_note"},
            {"image", "img", "branch_photo"},
            {"divider", "hr", "details_rule"},
            {"link", "a", "lending_rules"},
            {"button", "button", "details_continue"}
          ] do
        drawn = html(authored(name, %{"accessible_description" => "More."}), id_prefix: "second")
        id = "second-element-#{key}-accessible-description"

        assert drawn =~ ~s(id="#{id}"), name
        assert [node] = tags(drawn, tag)
        assert attr_value(node, "aria-describedby") == id, name
      end
    end

    # Mutation: draw the description of a link riddler presents with no href - goes red.
    test "is not drawn for an element that draws nothing" do
      for element <- [
            authored("link", %{"href" => nil, "accessible_description" => "Rules."}),
            authored("heading", %{"text" => " ", "accessible_description" => "Rules."}),
            authored("image", %{"src" => nil, "accessible_description" => "Rules."}),
            authored("button", %{"outcome" => "not_offered", "accessible_description" => "Rules."})
          ] do
        refute html(element) =~ "accessible-description", element["type"]
      end
    end
  end

  describe "the label and description riddler presents" do
    # Mutation: read "accessible_label" from the element under another key - goes red.
    test "are drawn as riddler renders them from the document's templates" do
      document =
        Document.admit(%{
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
                  "label" => "Email",
                  "accessible_label" => "Email for {{ context.branch }} reminders",
                  "accessible_description" => "{{ context.branch }} sends one a week."
                }
              ]
            }
          ]
        })

      {:ok, answer} =
        Riddler.Journey.present(document, {:screen, "patron_details"}, %{
          "context" => %{"branch" => "Riverside"}
        })

      [element] = answer["screen"]["elements"]
      drawn = html(element)
      [input] = tags(drawn, "input")

      assert attr_value(input, "aria-label") == "Email for Riverside reminders"
      assert drawn =~ ">Riverside sends one a week.</span>"
    end
  end
end
