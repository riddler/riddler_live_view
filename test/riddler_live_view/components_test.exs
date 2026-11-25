defmodule RiddlerLiveView.ComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias RiddlerLiveView.Components

  @screen %{"key" => "details", "title" => "Patron registration", "elements" => []}
  @heading %{
    "type" => "heading",
    "key" => "details_heading",
    "level" => 2,
    "text" => "Your details"
  }
  @text %{
    "type" => "text",
    "key" => "reminder_note",
    "text" => "We send due-date reminders to this address."
  }

  defp frame_html(screen, progress) do
    assigns = %{screen: screen, progress: progress}

    rendered_to_string(~H"""
    <Components.frame screen={@screen} progress={@progress}>
      <span>an element</span>
    </Components.frame>
    """)
  end

  defp heading_html(element, class \\ nil) do
    assigns = %{element: element, class: class}
    rendered_to_string(~H"<Components.heading element={@element} class={@class} />")
  end

  defp text_html(element, class \\ nil) do
    assigns = %{element: element, class: class}
    rendered_to_string(~H"<Components.text element={@element} class={@class} />")
  end

  describe "frame/1" do
    # Mutation: give the <h1> an id other than the one aria-labelledby names - goes red.
    test "draws the title as the section's h1 and labels the section with it" do
      html = frame_html(@screen, nil)

      assert html =~ ~r/<section[^>]*class="riddler-screen"/
      assert html =~ ~s(data-riddler-screen="details")
      assert html =~ ~s(aria-labelledby="riddler-screen-details-title")

      assert html =~
               ~r{<h1 id="riddler-screen-details-title" class="riddler-screen-title" data-riddler-title>\s*Patron registration\s*</h1>}
    end

    # Mutation: render the <h1> whatever the title - goes red.
    test "draws no title and no label for a screen whose title is nil or blank" do
      for title <- [nil, "", "  "] do
        html = frame_html(%{@screen | "title" => title}, nil)

        refute html =~ "<h1"
        refute html =~ "aria-labelledby"
      end
    end

    # Mutation: drop the :if on <progress> - goes red.
    test "draws no progress when the answer carries none" do
      refute frame_html(@screen, nil) =~ "progress"
    end

    # Mutation: swap value and max on <progress> - goes red.
    test "draws progress as the host supplied it" do
      html = frame_html(@screen, %{"step" => 2, "of" => 5})

      assert html =~
               ~r{<progress class="riddler-progress" data-riddler-progress value="2" max="5" aria-label="Progress">\s*2 / 5\s*</progress>}
    end

    # Mutation: ignore @progress_label and always name the bar "Progress" - goes red.
    test "names the progress bar with the label a host passes" do
      assigns = %{screen: @screen}

      html =
        rendered_to_string(~H"""
        <Components.frame
          screen={@screen}
          progress={%{"step" => 1, "of" => 2}}
          progress_label="Registration steps"
        >
          x
        </Components.frame>
        """)

      assert html =~ ~s(aria-label="Registration steps")
    end

    # Mutation: drop render_slot(@inner_block) - goes red.
    test "renders the elements inside the elements container" do
      assert frame_html(@screen, nil) =~
               ~r{<div class="riddler-elements" data-riddler-elements>\s*<span>an element</span>\s*</div>}
    end

    # Mutation: drop @class from the section's class list - goes red.
    test "adds a host's classes to its own" do
      assigns = %{screen: @screen}

      html =
        rendered_to_string(~H"""
        <Components.frame screen={@screen} class="registration">x</Components.frame>
        """)

      assert html =~ ~s(class="riddler-screen registration")
    end
  end

  describe "heading/1" do
    # Mutation: hard-code tag_name to "h2" - goes red on every other level.
    test "renders each level as its own HTML heading" do
      for level <- 1..6 do
        html = heading_html(%{@heading | "level" => level})

        assert [_, attrs] =
                 Regex.run(~r{^<h#{level}\b([^>]*)>\s*Your details\s*</h#{level}>$}, html)

        assert attrs =~ ~s( class="riddler-heading")
        assert attrs =~ ~s( data-riddler-element="heading")
        assert attrs =~ ~s( data-riddler-key="details_heading")
      end
    end

    # Mutation: drop the :if on the dynamic tag - goes red.
    test "renders nothing for a heading whose text is blank" do
      assert heading_html(%{@heading | "text" => ""}) == ""
      assert heading_html(%{@heading | "text" => " \n"}) == ""
      assert heading_html(%{@heading | "text" => nil}) == ""
    end

    # Mutation: accept any integer level in heading_tag/1 - goes red.
    test "raises for a level riddler never presents" do
      for level <- [0, 7, "2", nil] do
        assert_raise ArgumentError, ~r/from 1 to 6/, fn ->
          heading_html(%{@heading | "level" => level})
        end
      end
    end

    # Mutation: drop @class from the heading's class list - goes red.
    test "adds a host's classes to its own" do
      assert heading_html(@heading, "lead") =~ ~s(class="riddler-heading lead")
    end
  end

  describe "text/1" do
    # Mutation: render the text in a <div> - goes red.
    test "renders the text as a paragraph" do
      assert text_html(@text) =~
               ~r{^<p class="riddler-text" data-riddler-element="text" data-riddler-key="reminder_note">\s*We send due-date reminders to this address.\s*</p>$}
    end

    # Mutation: render the text with raw/1 - goes red.
    test "escapes the text" do
      html = text_html(%{@text | "text" => "<b>Ada</b> & co"})

      assert html =~ "&lt;b&gt;Ada&lt;/b&gt; &amp; co"
      refute html =~ "<b>"
    end

    # Mutation: drop @class from the paragraph's class list - goes red.
    test "adds a host's classes to its own" do
      assert text_html(@text, "note") =~ ~s(class="riddler-text note")
    end
  end

  describe "text_question/1" do
    @email %{
      "type" => "text_question",
      "key" => "reminder_email",
      "label" => "Email for reminders",
      "format" => "email"
    }

    defp text_question_html(element, attrs \\ %{}) do
      assigns = Map.merge(%{element: element, name: nil, class: nil}, attrs)

      rendered_to_string(
        ~H"<Components.text_question element={@element} name={@name} class={@class} />"
      )
    end

    # Mutation: point the label's for at an id the input does not carry - goes red.
    test "renders the label for the input, keyed by the element" do
      html = text_question_html(@email)

      assert html =~
               ~r{^<div class="riddler-text-question" data-riddler-element="text_question" data-riddler-key="reminder_email">}

      assert html =~
               ~r{<label for="riddler-element-reminder_email" class="riddler-label" data-riddler-label>Email for reminders</label>}

      assert [_, attrs] = Regex.run(~r{<input([^>]*)>}, html)
      assert attrs =~ ~s( id="riddler-element-reminder_email")
      assert attrs =~ ~s( name="reminder_email")
      assert attrs =~ ~s( class="riddler-input")
      assert attrs =~ ~s( data-riddler-input)
    end

    # Mutation: answer "text" for every format in input_type/1 - goes red.
    test "picks the input type from the format" do
      for {format, type} <- [
            {"email", "email"},
            {"phone", "tel"},
            {"pattern", "text"},
            {"integer", "text"},
            {"number", "text"},
            {nil, "text"}
          ] do
        assert text_question_html(%{@email | "format" => format}) =~ ~s(<input type="#{type}")
      end
    end

    # Mutation: copy the element's pattern, min or max onto the input - goes red.
    test "leaves a format's pattern and bounds to riddler's validation" do
      html =
        text_question_html(
          Map.merge(@email, %{
            "format" => "integer",
            "min" => 1,
            "max" => 9,
            "pattern" => "[0-9]+"
          })
        )

      refute html =~ ~r/\s(pattern|min|max)=/
    end

    # Mutation: drop value={@value} from the input - goes red.
    test "draws the presented value, and no value where none is presented or it is not text" do
      assert text_question_html(Map.put(@email, "value", "ada@example.org")) =~
               ~s(value="ada@example.org")

      assert text_question_html(%{@email | "format" => "integer"} |> Map.put("value", 2)) =~
               ~s(value="2")

      refute text_question_html(@email) =~ "value="
      refute text_question_html(Map.put(@email, "value", %{"a" => 1})) =~ "value="
    end

    # Mutation: render the value with raw/1 - goes red.
    test "escapes the label and the value" do
      html =
        text_question_html(%{@email | "label" => "<b>Email</b>"} |> Map.put("value", ~s("><b>)))

      refute html =~ "<b>"
      assert html =~ "&lt;b&gt;Email&lt;/b&gt;"
    end

    # Mutation: render required whatever the element says - goes red.
    test "marks the input required only where the question is" do
      assert text_question_html(Map.put(@email, "required", true)) =~ ~r{<input[^>]* required[ >]}
      refute text_question_html(Map.put(@email, "required", false)) =~ "required"
      refute text_question_html(@email) =~ "required"
    end

    # Mutation: drop the placeholder attribute - goes red.
    test "carries the placeholder" do
      assert text_question_html(Map.put(@email, "placeholder", "name@example.org")) =~
               ~s(placeholder="name@example.org")
    end

    # Mutation: drop aria-describedby from the input - goes red.
    test "draws the help and names it as the input's description" do
      html = text_question_html(Map.put(@email, "help", "We send one reminder a week."))

      assert html =~ ~s(aria-describedby="riddler-element-reminder_email-help")

      assert html =~
               ~r{<p id="riddler-element-reminder_email-help" class="riddler-help" data-riddler-help>We send one reminder a week.</p>}

      for help <- [nil, " "] do
        html = text_question_html(Map.put(@email, "help", help))
        refute html =~ "riddler-help"
        refute html =~ "aria-describedby"
      end
    end

    # Mutation: ignore @name and always name the input by its key - goes red.
    test "names the input by the key unless the host passes a name" do
      assert text_question_html(@email, %{name: "responses[reminder_email]"}) =~
               ~s(name="responses[reminder_email]")
    end

    # Mutation: drop @class from the question's class list - goes red.
    test "adds a host's classes to its own" do
      assert text_question_html(@email, %{class: "wide"}) =~
               ~s(class="riddler-text-question wide")
    end
  end

  describe "secret_question/1" do
    @pin %{
      "type" => "secret_question",
      "key" => "card_pin",
      "label" => "Library card PIN",
      "held" => false
    }

    defp secret_html(element, attrs \\ %{}) do
      assigns = Map.merge(%{element: element, name: nil, class: nil}, attrs)

      rendered_to_string(
        ~H"<Components.secret_question element={@element} name={@name} class={@class} />"
      )
    end

    # Mutation: render the input as type="text" - goes red.
    test "renders a labelled password input with autocomplete off" do
      html = secret_html(@pin)

      assert html =~
               ~r{^<div class="riddler-secret-question" data-riddler-element="secret_question" data-riddler-key="card_pin">}

      assert html =~
               ~r{<label for="riddler-element-card_pin" class="riddler-label" data-riddler-label>Library card PIN</label>}

      assert [_, attrs] = Regex.run(~r{<input([^>]*)>}, html)
      assert attrs =~ ~s( type="password")
      assert attrs =~ ~s( id="riddler-element-card_pin")
      assert attrs =~ ~s( name="card_pin")
      assert attrs =~ ~s( autocomplete="off")
      assert attrs =~ ~s( class="riddler-input")
    end

    # Mutation: value the input, value={@element["value"]} - goes red.
    test "never draws a value, whatever the element carries" do
      sentinel = "pin-sentinel-5150"

      for element <- [
            Map.put(@pin, "value", sentinel),
            Map.merge(@pin, %{"held" => true, "value" => sentinel}),
            Map.put(@pin, "value", %{"sealed" => sentinel})
          ] do
        html = secret_html(element)

        refute html =~ sentinel
        refute html =~ ~r/\svalue=/
      end
    end

    # Mutation: drop the :if on the held paragraph - goes red.
    test "says a value is held only where one is" do
      html = secret_html(%{@pin | "held" => true})

      assert html =~
               ~r{<p id="riddler-element-card_pin-held" class="riddler-held" data-riddler-held>A value is held.</p>}

      assert html =~ ~s(aria-describedby="riddler-element-card_pin-held")

      for held <- [false, nil, "true"] do
        html = secret_html(%{@pin | "held" => held})
        refute html =~ "riddler-held"
        refute html =~ "aria-describedby"
      end
    end

    # Mutation: ignore @held_text - goes red.
    test "shows the held text a host passes" do
      assigns = %{element: %{@pin | "held" => true}}

      html =
        rendered_to_string(
          ~H|<Components.secret_question element={@element} held_text="Your PIN is set." />|
        )

      assert html =~ ">Your PIN is set.</p>"
    end

    # Mutation: mark the input required whatever is held - goes red.
    test "marks the input required only where the question is and nothing is held" do
      required = Map.put(@pin, "required", true)

      assert secret_html(required) =~ ~r{<input[^>]* required[ >]}
      refute secret_html(%{required | "held" => true}) =~ "required"
      refute secret_html(@pin) =~ "required"
    end

    # Mutation: name only the help in aria-describedby - goes red.
    test "names the held paragraph and the help as the input's description" do
      html = secret_html(Map.merge(@pin, %{"held" => true, "help" => "Four digits."}))

      assert html =~
               ~s(aria-describedby="riddler-element-card_pin-held riddler-element-card_pin-help")

      assert html =~
               ~r{<p id="riddler-element-card_pin-help" class="riddler-help" data-riddler-help>Four digits.</p>}

      assert secret_html(Map.put(@pin, "help", "Four digits.")) =~
               ~s(aria-describedby="riddler-element-card_pin-help")
    end

    # Mutation: ignore @name and always name the input by its key - goes red.
    test "names the input by the key unless the host passes a name" do
      assert secret_html(@pin, %{name: "responses[card_pin]"}) =~ ~s(name="responses[card_pin]")
    end

    # Mutation: drop @class from the question's class list - goes red.
    test "adds a host's classes to its own" do
      assert secret_html(@pin, %{class: "pin"}) =~ ~s(class="riddler-secret-question pin")
    end
  end
end
