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
      {"frame around a level 1 heading and a text", composed()}
    ]
  end

  defp rules do
    [
      {"no inline style and no style element", &no_style/1},
      {"every component carries a class", &component_has_class/1},
      {"no empty heading", &no_empty_heading/1},
      {"aria-labelledby names an id in the markup", &labelledby_resolves/1},
      {"no duplicate id", &ids_unique/1},
      {"a progress bar has a name, a max and a value within it", &progress_named_and_bounded/1}
    ]
  end

  @rule_names [
    "no inline style and no style element",
    "every component carries a class",
    "no empty heading",
    "aria-labelledby names an id in the markup",
    "no duplicate id",
    "a progress bar has a name, a max and a value within it"
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
        ~s(<section class="" data-riddler-screen="s">x</section>)
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
    ~r/<[a-z0-9]+\b([^>]*\bdata-riddler-(?:element|screen|title|progress|elements)\b[^>]*)>/
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
end
