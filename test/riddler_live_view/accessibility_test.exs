defmodule RiddlerLiveView.AccessibilityTest do
  @moduledoc """
  Deterministic accessibility rules over the HTML the components render.

  Each rule is a function from rendered markup to a list of violations; an
  empty list passes. Every rule runs over every case of every component, so
  a component that breaks a rule fails the gate. A component joins by adding
  its cases to `cases/0`; a rule joins by adding a clause to `rules/0`, its
  name to `@rule_names` and its bad markup to the rules' own test.
  """

  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias RiddlerLiveView.Components

  @screen %{"key" => "details", "title" => "Patron registration", "elements" => []}

  defp cases do
    [
      {"frame with title", frame(@screen, nil)},
      {"frame with title and progress", frame(@screen, %{"step" => 1, "of" => 3})},
      {"frame without title, with progress",
       frame(%{@screen | "title" => nil}, %{"step" => 3, "of" => 3})},
      {"heading level 1", heading(1, "Patron registration")},
      {"heading level 4", heading(4, "Your library card")},
      {"heading with blank text", heading(2, " ")},
      {"text", text("Bring a proof of address to the branch.")},
      {"frame around a level 1 heading and a text", composed()},
      {"text question", text_question(%{})},
      {"text question, required, with help and a value",
       text_question(%{
         "required" => true,
         "help" => "One reminder a week.",
         "value" => "ada@example.org"
       })},
      {"text question, phone format", text_question(%{"format" => "phone", "key" => "phone"})},
      {"secret question", secret_question(%{})},
      {"secret question, held", secret_question(%{"held" => true})},
      {"secret question, required, held, with help",
       secret_question(%{"held" => true, "required" => true, "help" => "Four digits."})},
      {"frame around a text question and a secret question", questions()},
      {"choice question, one", choice_question(%{})},
      {"choice question, one, required, with help and a value",
       choice_question(%{
         "required" => true,
         "help" => "Change it at the desk.",
         "value" => "child"
       })},
      {"choice question, one, dropdown",
       choice_question(%{"style" => "dropdown", "value" => "adult"})},
      {"choice question, many, with bounds and values",
       choice_question(%{
         "select" => "many",
         "min_selections" => 1,
         "max_selections" => 2,
         "value" => ["adult", "child"]
       })},
      {"choice question, many, list, with help",
       choice_question(%{"select" => "many", "style" => "list", "help" => "Pick any."})},
      {"boolean question", boolean_question(%{})},
      {"boolean question, required, ticked, with help",
       boolean_question(%{"required" => true, "value" => true, "help" => "Twelve items."})},
      {"frame around a choice question and a boolean question", choices()},
      {"button", button(%{})},
      {"button that does not validate, with a style",
       button(%{"validates" => false, "style" => "secondary"})},
      {"back", back()},
      {"frame around a question, two buttons and back", moves()},
      {"text question with an author's finding and help",
       text_question(%{"help" => "Weekly."}, [
         finding("response.format", "reminder_email", "Check the address.")
       ])},
      {"secret question, held, with two findings and help",
       secret_question(%{"held" => true, "help" => "Four digits."}, [
         finding("response.required", "card_pin"),
         finding("response.invalid_shape", "card_pin")
       ])},
      {"choice question, one, with a finding",
       choice_question(%{"help" => "Ask."}, [finding("response.required", "card_type")])},
      {"choice question, many, list, with a finding",
       choice_question(%{"select" => "many", "style" => "list"}, [
         finding("response.out_of_range", "card_type")
       ])},
      {"boolean question with a finding",
       boolean_question(%{}, [finding("response.required", "agrees_to_rules")])},
      {"text question with another question's finding",
       text_question(%{}, [finding("response.required", "card_pin")])},
      {"frame around questions with their findings and the screen's own", refused(true)},
      {"frame around questions with their findings only", refused(false)},
      {"elements of the kinds the package draws", drawn_elements([])},
      {"elements with a kind nothing draws", drawn_elements([%{"type" => "rating_question"}])},
      {"elements with a host's own kind", hosted_elements()},
      {"journey on a screen with findings and back", journey(:screen)},
      {"journey waiting", journey(:waiting)},
      {"journey done", journey(:done)}
    ]
  end

  defp rules do
    [
      {"no inline style and no style element", &no_style/1},
      {"every component carries a class", &component_has_class/1},
      {"no empty heading", &no_empty_heading/1},
      {"aria-labelledby names an id in the markup", &labelledby_resolves/1},
      {"no duplicate id", &ids_unique/1},
      {"a progress bar has a name, a max and a value within it", &progress_named_and_bounded/1},
      {"every input has a label naming it", &input_labelled/1},
      {"aria-describedby names ids in the markup", &describedby_resolves/1},
      {"every fieldset opens on a legend with text", &fieldset_has_legend/1},
      {"every select is named by a label or by text it is labelled by", &select_named/1},
      {"every button has text", &button_has_text/1},
      {"every button says its type", &button_typed/1},
      {"aria-invalid only on a form control that names a finding", &invalid_names_finding/1},
      {"focus moves only to a finding in the markup that can take it", &focus_reaches_finding/1},
      {"a disabled button names text that says why", &disabled_button_says_why/1}
    ]
  end

  @rule_names [
    "no inline style and no style element",
    "every component carries a class",
    "no empty heading",
    "aria-labelledby names an id in the markup",
    "no duplicate id",
    "a progress bar has a name, a max and a value within it",
    "every input has a label naming it",
    "aria-describedby names ids in the markup",
    "every fieldset opens on a legend with text",
    "every select is named by a label or by text it is labelled by",
    "every button has text",
    "every button says its type",
    "aria-invalid only on a form control that names a finding",
    "focus moves only to a finding in the markup that can take it",
    "a disabled button names text that says why"
  ]

  for name <- @rule_names do
    # Mutation: per rule, the matching sabotage named on the rule's function below.
    test "accessibility rule holds over every component case: #{name}" do
      {name, check} = List.keyfind(rules(), unquote(name), 0)

      for {label, html} <- cases() do
        assert check.(html) == [], "#{name} fails on #{label}:\n#{html}"
      end
    end
  end

  test "every rule runs as a test of its own" do
    assert Enum.map(rules(), &elem(&1, 0)) == @rule_names
  end

  # The rules themselves are tested: each one reports the defect it names.
  test "every rule reports the markup it exists to refuse" do
    bad = %{
      "no inline style and no style element" => [
        ~s(<p class="a" style="color: red">x</p>),
        ~s(<style>p {}</style>)
      ],
      "every component carries a class" => [
        ~s(<p data-riddler-element="text">x</p>),
        ~s(<section class="" data-riddler-screen="s">x</section>),
        ~s(<legend data-riddler-legend>x</legend>),
        ~s(<option data-riddler-option="a"></option>),
        ~s(<button type="button" data-riddler-back>Back</button>),
        ~s(<p id="n" data-riddler-unknown="x">Cannot be sent.</p>)
      ],
      "no empty heading" => [~s(<h2 class="a"> </h2>), ~s(<h1></h1>)],
      "aria-labelledby names an id in the markup" => [
        ~s(<section class="a" aria-labelledby="missing"></section>),
        ~s(<section class="a" aria-labelledby=""></section>)
      ],
      "no duplicate id" => [~s(<h1 id="t">a</h1><h2 id="t">b</h2>)],
      "a progress bar has a name, a max and a value within it" => [
        ~s(<progress class="a" aria-label="P" value="4" max="3"></progress>),
        ~s(<progress class="a" value="1" max="3"></progress>),
        ~s(<progress class="a" aria-label="P" value="1"></progress>),
        ~s(<progress class="a" aria-label="P" max="3"></progress>)
      ],
      "every input has a label naming it" => [
        ~s(<input class="a" id="pin" type="password"/>),
        ~s(<label for="other">PIN</label><input class="a" id="pin"/>),
        ~s(<label for="pin"> </label><input class="a" id="pin"/>),
        ~s(<input class="a" type="text"/>)
      ],
      "aria-describedby names ids in the markup" => [
        ~s(<input class="a" aria-describedby="missing"/>),
        ~s(<p id="h">x</p><input class="a" aria-describedby="h missing"/>),
        ~s(<input class="a" aria-describedby=""/>)
      ],
      "every fieldset opens on a legend with text" => [
        ~s(<fieldset class="a"><input class="b"/></fieldset>),
        ~s(<fieldset class="a"><legend class="l"> </legend></fieldset>),
        ~s(<fieldset class="a"><p>x</p><legend class="l">Card</legend></fieldset>)
      ],
      "every select is named by a label or by text it is labelled by" => [
        ~s(<select class="a" id="s"></select>),
        ~s(<legend id="l"> </legend><select class="a" aria-labelledby="l"></select>),
        ~s(<label for="other">Card</label><select class="a" id="s"></select>),
        ~s(<select class="a" aria-labelledby="missing"></select>),
        ~s(<select class="a" id="s" aria-labelledby="s"><option>A</option></select>)
      ],
      "every button has text" => [
        ~s(<button class="a" type="submit"></button>),
        ~s(<button class="a" type="button">  </button>),
        ~s(<button class="a" type="button"><span></span></button>),
        ~s(<button class="a" type="submit">Continue</button><button class="b" type="button"></button>)
      ],
      "every button says its type" => [
        ~s(<button class="a">Continue</button>),
        ~s(<button class="a" type="">Continue</button>),
        ~s(<button class="a" type="reset">Clear</button>),
        ~s(<button class="a" data-type="submit">Continue</button>),
        ~s(<button class="a" type="submit">Continue</button><button class="b">Back</button>)
      ],
      "aria-invalid only on a form control that names a finding" => [
        ~s(<input class="a" aria-invalid="true"/>),
        ~s(<p id="h" class="h">Help</p><input class="a" aria-invalid="true" aria-describedby="h"/>),
        ~s(<p id="f" class="f" data-riddler-finding="x">F</p><div class="a" aria-invalid="true" aria-describedby="f"></div>),
        ~s(<input class="a" aria-invalid="false"/>)
      ],
      "focus moves only to a finding in the markup that can take it" => [
        ~s(<span class="a" hidden phx-mounted="[[&quot;focus&quot;,{&quot;to&quot;:&quot;#f&quot;}]]"></span>),
        ~s(<p id="f" class="f" data-riddler-finding="x">F</p><span class="a" phx-mounted="[[&quot;focus&quot;,{&quot;to&quot;:&quot;#f&quot;}]]"></span>),
        ~s(<p id="h" class="h" tabindex="-1">Help</p><span class="a" phx-mounted="[[&quot;focus&quot;,{&quot;to&quot;:&quot;#h&quot;}]]"></span>)
      ],
      "a disabled button names text that says why" => [
        ~s(<button class="a" type="submit" disabled>Continue</button>),
        ~s(<button class="a" type="submit" disabled aria-describedby="n">Continue</button>),
        ~s(<p id="n" class="n"> </p><button class="a" type="submit" disabled aria-describedby="n">Go</button>),
        ~s(<p id="n" class="n">Why.</p><button class="a" type="submit" disabled aria-describedby="">Go</button>)
      ]
    }

    for {name, check} <- rules(), markup <- Map.fetch!(bad, name) do
      assert check.(markup) != [], "#{name} passed bad markup: #{markup}"
    end

    good = ~s(<progress class="a" aria-label="P" value="3" max="3"></progress>)
    assert progress_named_and_bounded(good) == []
  end

  # Sabotage: render a style attribute on the frame's section.
  defp no_style(html) do
    Regex.scan(~r/<style\b|\sstyle=/, html) |> List.flatten()
  end

  # Sabotage: drop the class attribute from the text component's <p>.
  defp component_has_class(html) do
    ~r/<[a-z0-9]+\b([^>]*\bdata-riddler-(?:element|screen|title|progress|elements|label|input|help|held|legend|option|back|finding|focus|unknown|journey|waiting|done)\b[^>]*)>/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.reject(&(&1 =~ ~r/\sclass="[^"\s][^"]*"/))
  end

  # Sabotage: drop the blank-text guard from the heading component.
  defp no_empty_heading(html) do
    ~r{<h([1-6])\b[^>]*>(.*?)</h\1>}s
    |> Regex.scan(html, capture: :all_but_first)
    |> Enum.filter(fn [_level, text] -> String.trim(text) == "" end)
  end

  # Sabotage: point the text question's label at an id its input does not carry.
  defp input_labelled(html) do
    labels =
      ~r{<label\b[^>]*\sfor="([^"]+)"[^>]*>(.*?)</label>}s
      |> Regex.scan(html, capture: :all_but_first)
      |> Enum.reject(fn [_for, text] -> String.trim(text) == "" end)
      |> Enum.map(&hd/1)

    ~r/<input\b([^>]*)>/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.reject(fn attrs ->
      case Regex.run(~r/\sid="([^"]+)"/, attrs) do
        [_, id] -> id in labels
        nil -> false
      end
    end)
  end

  # Sabotage: name the secret question's held paragraph by an id it does not carry.
  defp describedby_resolves(html) do
    ids = ids(html)

    ~r/aria-describedby="([^"]*)"/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.flat_map(fn value ->
      case String.split(value) do
        [] -> [value]
        names -> Enum.reject(names, &(&1 in ids))
      end
    end)
  end

  # Sabotage: draw the choice question's legend after its options.
  defp fieldset_has_legend(html) do
    ~r{<fieldset\b[^>]*>\s*(.*?)</fieldset>}s
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.reject(fn inner ->
      case Regex.run(~r{\A<legend\b[^>]*>(.*?)</legend>}s, inner) do
        [_, text] -> String.trim(text) != ""
        nil -> false
      end
    end)
  end

  # Sabotage: render the button component with no text.
  defp button_has_text(html) do
    ~r{<button\b[^>]*>(.*?)</button>}s
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.filter(&(&1 |> String.replace(~r/<[^>]*>/, "") |> String.trim() == ""))
  end

  # Sabotage: drop type="button" from the Back control.
  defp button_typed(html) do
    ~r/<button\b([^>]*)>/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.reject(&(&1 =~ ~r/\stype="(?:submit|button)"/))
  end

  # Sabotage: point the select's aria-labelledby at an id the legend does not carry.
  defp select_named(html) do
    labels =
      ~r{<label\b[^>]*\sfor="([^"]+)"[^>]*>(.*?)</label>}s
      |> Regex.scan(html, capture: :all_but_first)
      |> Enum.reject(fn [_for, text] -> String.trim(text) == "" end)
      |> Enum.map(&hd/1)

    texts =
      ~r{<([a-z0-9]+)\b[^>]*\sid="([^"]+)"[^>]*>(.*?)</\1>}s
      |> Regex.scan(html, capture: :all_but_first)
      |> Enum.reject(fn [tag, _id, text] -> tag == "select" or String.trim(text) == "" end)
      |> Enum.map(fn [_tag, id, _text] -> id end)

    ~r/<select\b([^>]*)>/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.reject(fn attrs -> select_named?(attrs, labels, texts) end)
  end

  defp select_named?(attrs, labels, texts) do
    by_label =
      case Regex.run(~r/\sid="([^"]+)"/, attrs) do
        [_, id] -> id in labels
        nil -> false
      end

    by_text =
      case Regex.run(~r/\saria-labelledby="([^"]+)"/, attrs) do
        [_, names] -> names |> String.split() |> Enum.all?(&(&1 in texts))
        nil -> false
      end

    by_label or by_text
  end

  # Sabotage: label the section with a title id the <h1> does not carry.
  defp labelledby_resolves(html) do
    ids = ids(html)

    ~r/aria-labelledby="([^"]*)"/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.flat_map(fn value ->
      case String.split(value) do
        [] -> [value]
        names -> Enum.reject(names, &(&1 in ids))
      end
    end)
  end

  # Sabotage: give the elements container the title's id.
  defp ids_unique(html) do
    ids = ids(html)
    ids -- Enum.uniq(ids)
  end

  # Sabotage: drop aria-label from the frame's <progress>.
  defp progress_named_and_bounded(html) do
    ~r/<progress\b([^>]*)>/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.reject(&progress_ok?/1)
  end

  defp progress_ok?(attrs) do
    named = attrs =~ ~r/\saria-label="[^"\s][^"]*"/ or attrs =~ ~r/\saria-labelledby="/

    with true <- named,
         [_, value] <- Regex.run(~r/\svalue="(\d+)"/, attrs),
         [_, max] <- Regex.run(~r/\smax="(\d+)"/, attrs) do
      String.to_integer(value) <= String.to_integer(max)
    else
      _ -> false
    end
  end

  # Sabotage: set aria-invalid on the text question's input whatever its findings.
  defp invalid_names_finding(html) do
    findings =
      ~r/<[a-z]+\b[^>]*\sid="([^"]+)"[^>]*\sdata-riddler-finding="/
      |> Regex.scan(html, capture: :all_but_first)
      |> List.flatten()

    ~r/<([a-z]+)\b([^>]*\saria-invalid="[^"]*"[^>]*)>/
    |> Regex.scan(html, capture: :all_but_first)
    |> Enum.reject(fn [tag, attrs] ->
      described =
        case Regex.run(~r/\saria-describedby="([^"]*)"/, attrs) do
          [_, names] -> String.split(names)
          nil -> []
        end

      tag in ~w(input select textarea) and attrs =~ ~s( aria-invalid="true") and
        Enum.any?(described, &(&1 in findings))
    end)
  end

  # Sabotage: drop tabindex="-1" from the finding paragraph.
  defp focus_reaches_finding(html) do
    findings =
      ~r/<[a-z]+\b([^>]*\bdata-riddler-finding="[^>]*)>/
      |> Regex.scan(html, capture: :all_but_first)
      |> List.flatten()
      |> Enum.filter(&(&1 =~ ~s( tabindex="-1")))
      |> Enum.flat_map(&(Regex.run(~r/\sid="([^"]+)"/, &1, capture: :all_but_first) || []))

    ~r/\sphx-mounted="([^"]*)"/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.flat_map(fn json ->
      json
      |> String.replace("&quot;", "\"")
      |> String.replace("&amp;", "&")
      |> Jason.decode!()
      |> Enum.flat_map(&unreached_focus(&1, findings))
    end)
  end

  defp unreached_focus(["focus", %{"to" => "#" <> id}], findings),
    do: if(id in findings, do: [], else: [id])

  defp unreached_focus(command, _findings), do: [inspect(command)]

  # Sabotage: drop aria-describedby from the button component.
  defp disabled_button_says_why(html) do
    texts =
      ~r{<([a-z0-9]+)\b[^>]*\sid="([^"]+)"[^>]*>(.*?)</\1>}s
      |> Regex.scan(html, capture: :all_but_first)
      |> Enum.reject(fn [_tag, _id, text] ->
        text |> String.replace(~r/<[^>]*>/, "") |> String.trim() == ""
      end)
      |> Enum.map(fn [_tag, id, _text] -> id end)

    ~r/<button\b([^>]*)>/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.filter(&(&1 =~ ~r/\sdisabled(?:[\s=>]|$)/))
    |> Enum.reject(fn attrs ->
      case Regex.run(~r/\saria-describedby="([^"]+)"/, attrs) do
        [_, ids] -> Enum.any?(String.split(ids), &(&1 in texts))
        nil -> false
      end
    end)
  end

  defp finding(code, element_key, author_message \\ nil) do
    %{
      "code" => code,
      "message" => "m",
      "element_key" => element_key,
      "author_message" => author_message
    }
  end

  defp refused(screen_level?) do
    findings =
      [
        finding("response.format", "reminder_email"),
        finding("response.required", "card_pin"),
        finding("response.required", "card_type"),
        finding("response.required", "agrees_to_rules")
      ] ++ if(screen_level?, do: [finding("submit.missing_field", nil)], else: [])

    assigns = %{
      screen: %{
        @screen
        | "elements" => [
            %{"type" => "text_question", "key" => "reminder_email"},
            %{"type" => "secret_question", "key" => "card_pin"},
            %{"type" => "choice_question", "key" => "card_type"},
            %{"type" => "boolean_question", "key" => "agrees_to_rules"}
          ]
      },
      findings: findings,
      email: %{"key" => "reminder_email", "label" => "Email", "help" => "Weekly."},
      pin: %{"key" => "card_pin", "label" => "Card PIN", "held" => true},
      card: %{
        "key" => "card_type",
        "label" => "Card",
        "select" => "one",
        "help" => "Ask.",
        "answer_options" => [%{"value" => "adult", "label" => "Adult card"}]
      },
      rules: %{"key" => "agrees_to_rules", "label" => "I agree."}
    }

    rendered_to_string(~H"""
    <Components.frame screen={@screen} findings={@findings}>
      <Components.text_question element={@email} findings={@findings} />
      <Components.secret_question element={@pin} findings={@findings} />
      <Components.choice_question element={@card} findings={@findings} />
      <Components.boolean_question element={@rules} findings={@findings} />
    </Components.frame>
    """)
  end

  defp drawn_elements(extra) do
    assigns = %{
      screen: %{
        "key" => "details",
        "elements" =>
          [
            %{"type" => "heading", "key" => "details_heading", "level" => 1, "text" => "Details"},
            %{"type" => "text", "key" => "address_note", "text" => "Your address."},
            %{"type" => "text_question", "key" => "reminder_email", "label" => "Email"},
            %{"type" => "secret_question", "key" => "card_pin", "label" => "PIN", "held" => true},
            %{
              "type" => "choice_question",
              "key" => "card_type",
              "label" => "Card",
              "select" => "one",
              "answer_options" => [%{"value" => "adult", "label" => "Adult card"}]
            },
            %{"type" => "boolean_question", "key" => "agrees_to_rules", "label" => "I agree."},
            %{
              "type" => "button",
              "key" => "details_continue",
              "label" => "Continue",
              "outcome" => "details_submitted"
            }
          ] ++ extra
      },
      moves: %{"outcomes" => ["details_submitted"], "back" => true}
    }

    rendered_to_string(~H"""
    <Components.frame screen={@screen}>
      <Components.elements screen={@screen} moves={@moves} />
    </Components.frame>
    """)
  end

  defp hosted_elements do
    assigns = %{
      screen: %{
        "key" => "details",
        "elements" => [
          %{"type" => "branch_map", "key" => "pickup_branch"},
          %{
            "type" => "button",
            "key" => "details_continue",
            "label" => "Continue",
            "outcome" => "details_submitted"
          }
        ]
      },
      moves: %{"outcomes" => ["details_submitted"], "back" => true},
      components: %{"branch_map" => &branch_map/1}
    }

    rendered_to_string(~H"""
    <Components.frame screen={@screen}>
      <Components.elements screen={@screen} moves={@moves} components={@components} />
    </Components.frame>
    """)
  end

  defp branch_map(assigns) do
    ~H"""
    <p class="branch-map" data-riddler-element="branch_map">Riverside branch</p>
    """
  end

  defp ids(html) do
    ~r/\sid="([^"]*)"/ |> Regex.scan(html, capture: :all_but_first) |> List.flatten()
  end

  defp frame(screen, progress) do
    assigns = %{screen: screen, progress: progress}

    rendered_to_string(~H"""
    <Components.frame screen={@screen} progress={@progress}>
      <Components.text element={%{"key" => "note", "text" => "Welcome."}} />
    </Components.frame>
    """)
  end

  defp composed do
    assigns = %{screen: @screen}

    rendered_to_string(~H"""
    <Components.frame screen={@screen} progress={%{"step" => 2, "of" => 3}}>
      <Components.heading element={%{"key" => "details_heading", "level" => 1, "text" => "Details"}} />
      <Components.heading element={%{"key" => "blank_heading", "level" => 2, "text" => ""}} />
      <Components.text element={%{"key" => "address_note", "text" => "Your address."}} />
    </Components.frame>
    """)
  end

  defp heading(level, text) do
    assigns = %{element: %{"key" => "card_heading", "level" => level, "text" => text}}
    rendered_to_string(~H"<Components.heading element={@element} />")
  end

  defp text(text) do
    assigns = %{element: %{"key" => "address_note", "text" => text}}
    rendered_to_string(~H"<Components.text element={@element} />")
  end

  defp text_question(fields, findings \\ []) do
    element =
      Map.merge(
        %{
          "type" => "text_question",
          "key" => "reminder_email",
          "label" => "Email",
          "format" => "email"
        },
        fields
      )

    assigns = %{element: element, findings: findings}
    rendered_to_string(~H"<Components.text_question element={@element} findings={@findings} />")
  end

  defp secret_question(fields, findings \\ []) do
    element =
      Map.merge(
        %{
          "type" => "secret_question",
          "key" => "card_pin",
          "label" => "Card PIN",
          "held" => false
        },
        fields
      )

    assigns = %{element: element, findings: findings}
    rendered_to_string(~H"<Components.secret_question element={@element} findings={@findings} />")
  end

  defp choice_question(fields, findings \\ []) do
    element =
      Map.merge(
        %{
          "type" => "choice_question",
          "key" => "card_type",
          "label" => "Which library card would you like?",
          "select" => "one",
          "answer_options" => [
            %{"value" => "adult", "label" => "Adult card"},
            %{"value" => "child", "label" => "Child card"}
          ]
        },
        fields
      )

    assigns = %{element: element, findings: findings}
    rendered_to_string(~H"<Components.choice_question element={@element} findings={@findings} />")
  end

  defp boolean_question(fields, findings \\ []) do
    element =
      Map.merge(
        %{
          "type" => "boolean_question",
          "key" => "agrees_to_rules",
          "label" => "I agree to the borrowing rules."
        },
        fields
      )

    assigns = %{element: element, findings: findings}

    rendered_to_string(
      ~H"<Components.boolean_question element={@element} findings={@findings} />"
    )
  end

  defp choices do
    assigns = %{
      screen: @screen,
      card: %{
        "key" => "card_type",
        "label" => "Card",
        "select" => "one",
        "style" => "dropdown",
        "help" => "Ask at the desk.",
        "answer_options" => [%{"value" => "adult", "label" => "Adult card"}]
      },
      branches: %{
        "key" => "pickup_branches",
        "label" => "Branches",
        "select" => "many",
        "help" => "Any.",
        "answer_options" => [
          %{"value" => "riverside", "label" => "Riverside"},
          %{"value" => "hillcrest", "label" => "Hillcrest"}
        ]
      },
      rules: %{"key" => "agrees_to_rules", "label" => "I agree.", "help" => "Twelve items."}
    }

    rendered_to_string(~H"""
    <Components.frame screen={@screen}>
      <Components.choice_question element={@card} />
      <Components.choice_question element={@branches} />
      <Components.boolean_question element={@rules} />
    </Components.frame>
    """)
  end

  @moves %{"outcomes" => ["details_submitted", "card_type_changed"], "back" => true}

  defp button(fields) do
    element =
      Map.merge(
        %{
          "type" => "button",
          "key" => "details_continue",
          "label" => "Continue",
          "outcome" => "details_submitted"
        },
        fields
      )

    assigns = %{element: element, moves: @moves}
    rendered_to_string(~H"<Components.button element={@element} moves={@moves} />")
  end

  defp back do
    assigns = %{screen: @screen, moves: @moves}
    rendered_to_string(~H"<Components.back screen={@screen} moves={@moves} />")
  end

  defp moves do
    assigns = %{
      screen: @screen,
      moves: @moves,
      email: %{"key" => "reminder_email", "label" => "Email", "required" => true},
      continue: %{
        "key" => "details_continue",
        "label" => "Continue",
        "outcome" => "details_submitted",
        "style" => "primary"
      },
      change: %{
        "key" => "details_change",
        "label" => "Change card type",
        "outcome" => "card_type_changed",
        "validates" => false
      }
    }

    rendered_to_string(~H"""
    <Components.frame screen={@screen}>
      <Components.text_question element={@email} />
      <Components.button element={@continue} moves={@moves} />
      <Components.button element={@change} moves={@moves} />
      <Components.back screen={@screen} moves={@moves} />
    </Components.frame>
    """)
  end

  defp journey(state) do
    screen = %{
      "key" => "details",
      "title" => "Patron registration",
      "elements" => [
        %{"type" => "text_question", "key" => "reminder_email", "label" => "Email"},
        %{
          "type" => "secret_question",
          "key" => "card_pin",
          "label" => "Card PIN",
          "held" => true
        },
        %{
          "type" => "button",
          "key" => "details_continue",
          "label" => "Continue",
          "outcome" => "details_submitted"
        }
      ]
    }

    answer =
      case state do
        :screen ->
          %{
            "state" => "screen",
            "screen" => screen,
            "moves" => %{"outcomes" => ["details_submitted"], "back" => true},
            "progress" => %{"step" => 2, "of" => 3}
          }

        :waiting ->
          %{"state" => "waiting", "reason" => "card_number_pending", "retry_after_ms" => 5000}

        :done ->
          %{"state" => "done"}
      end

    assigns = %{
      __changed__: nil,
      id: "registration",
      class: nil,
      answer: answer,
      findings: [
        finding("response.format", "reminder_email"),
        finding("response.invalid_shape", nil)
      ],
      finding_text: %{},
      refusals: 2,
      id_prefix: nil,
      components: %{},
      unknown_text: nil,
      waiting_text: "One moment.",
      done_text: "All done.",
      myself: %Phoenix.LiveComponent.CID{cid: 1}
    }

    rendered_to_string(RiddlerLiveView.Journey.render(assigns))
  end

  defp questions do
    assigns = %{
      screen: @screen,
      email: %{"key" => "reminder_email", "label" => "Email", "help" => "Weekly."},
      pin: %{"key" => "card_pin", "label" => "Card PIN", "held" => true, "help" => "Four digits."}
    }

    rendered_to_string(~H"""
    <Components.frame screen={@screen}>
      <Components.text_question element={@email} />
      <Components.secret_question element={@pin} />
    </Components.frame>
    """)
  end
end
