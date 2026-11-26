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
               ~r{^<p class="riddler-text riddler-text-body" data-riddler-element="text" data-riddler-key="reminder_note">\s*We send due-date reminders to this address.\s*</p>$}
    end

    # Mutation: render the text with raw/1 - goes red.
    test "escapes the text" do
      html = text_html(%{@text | "text" => "<b>Ada</b> & co"})

      assert html =~ "&lt;b&gt;Ada&lt;/b&gt; &amp; co"
      refute html =~ "<b>"
    end

    # Mutation: drop @class from the paragraph's class list - goes red.
    test "adds a host's classes to its own" do
      assert text_html(@text, "note") =~ ~s(class="riddler-text riddler-text-body note")
    end
  end

  describe "text/1 with a style" do
    # Mutation: draw every text with the body class - goes red.
    test "draws the style as a class: caption, or body for body, none and any other" do
      assert text_html(Map.put(@text, "style", "caption")) =~
               ~s(class="riddler-text riddler-text-caption")

      for style <- ["body", nil, "footnote", 3] do
        html = text_html(Map.put(@text, "style", style))
        assert html =~ ~s(class="riddler-text riddler-text-body")
        refute html =~ "riddler-text-caption"
        refute html =~ "data-riddler-style"
      end
    end
  end

  describe "image/1" do
    @branch_photo %{
      "type" => "image",
      "key" => "branch_photo",
      "src" => "https://library.example.org/branches/riverside.png",
      "alt" => "The front of the Riverside branch",
      "size" => "medium",
      "fit" => "cover"
    }

    defp image_html(element, class \\ nil) do
      assigns = %{element: element, class: class}
      rendered_to_string(~H"<Components.image element={@element} class={@class} />")
    end

    # Mutation: render the image in a <figure> with no <img> - goes red.
    test "renders an img with its src, alt, size and fit" do
      assert image_html(@branch_photo) ==
               ~s(<img src="https://library.example.org/branches/riverside.png" alt="The front of the Riverside branch" class="riddler-image" data-riddler-element="image" data-riddler-key="branch_photo" data-riddler-size="medium" data-riddler-fit="cover">)
    end

    # Mutation: draw alt={present_text(@element["alt"])}, dropping an empty alt - goes red.
    test "draws alt=\"\" for a decorative image, and for an alt that is not a string" do
      for alt <- ["", nil] do
        html = image_html(Map.put(@branch_photo, "alt", alt))
        assert [_, attrs] = Regex.run(~r{<img([^>]*)>}, html)
        assert attrs =~ ~r/\salt=""(?=\s|\z)/
      end
    end

    # Mutation: carry size and fit whatever their shape - goes red.
    test "carries size and fit only where they are strings" do
      html = image_html(Map.drop(@branch_photo, ["size", "fit"]))
      refute html =~ "data-riddler-size"
      refute html =~ "data-riddler-fit"

      html = image_html(%{@branch_photo | "size" => 4, "fit" => %{}})
      refute html =~ "data-riddler-size"
      refute html =~ "data-riddler-fit"
    end

    # Mutation: render the image whatever its src - goes red.
    test "renders nothing for an image with no src" do
      assert image_html(Map.delete(@branch_photo, "src")) == ""
      assert image_html(%{@branch_photo | "src" => " "}) == ""
    end

    # Mutation: draw a data: image only where it begins https - goes red.
    test "draws a src riddler presents as written, a host-relative and a data: image" do
      for src <- ["/images/riverside.png", "data:image/png;base64,iVBORw0KGgo="] do
        assert image_html(%{@branch_photo | "src" => src}) =~ ~s(src="#{src}")
      end
    end

    # Mutation: render the alt with raw/1 - goes red.
    test "escapes the alt and the src" do
      html = image_html(%{@branch_photo | "alt" => "\"><b>Ada</b>", "src" => "/a?b=1&c=2"})
      refute html =~ "<b>"
      assert html =~ ~s(alt="&quot;&gt;&lt;b&gt;Ada&lt;/b&gt;")
      assert html =~ ~s(src="/a?b=1&amp;c=2")
    end

    # Mutation: drop @class from the image's class list - goes red.
    test "adds a host's classes to its own" do
      assert image_html(@branch_photo, "photo") =~ ~s(class="riddler-image photo")
    end
  end

  describe "divider/1" do
    @rule %{"type" => "divider", "key" => "details_rule"}

    defp divider_html(element, class \\ nil) do
      assigns = %{element: element, class: class}
      rendered_to_string(~H"<Components.divider element={@element} class={@class} />")
    end

    # Mutation: render the divider as a <div> - goes red.
    test "renders an hr" do
      assert divider_html(@rule) ==
               ~s(<hr class="riddler-divider" data-riddler-element="divider" data-riddler-key="details_rule">)
    end

    # Mutation: drop @class from the rule's class list - goes red.
    test "adds a host's classes to its own" do
      assert divider_html(@rule, "faint") =~ ~s(class="riddler-divider faint")
    end
  end

  describe "link/1" do
    @lending_rules %{
      "type" => "link",
      "key" => "lending_rules",
      "label" => "Read the lending rules",
      "href" => "https://library.example.org/lending-rules",
      "style" => "inline"
    }

    defp link_html(element, class \\ nil) do
      assigns = %{element: element, class: class}
      rendered_to_string(~H"<Components.link element={@element} class={@class} />")
    end

    # Mutation: render the link as a <button> - goes red.
    test "renders an a whose href is the link's and whose text is its label" do
      assert link_html(@lending_rules) =~
               ~r{^<a href="https://library.example.org/lending-rules" class="riddler-link" data-riddler-element="link" data-riddler-key="lending_rules" data-riddler-style="inline">\s*Read the lending rules\s*</a>$}
    end

    # Mutation: add phx-click={JS.push("submit", value: %{"outcome" => @element["key"]})} to the a - goes red.
    test "never submits and raises no outcome" do
      html = link_html(@lending_rules)
      assert [_, attrs] = Regex.run(~r{<a([^>]*)>}, html)

      refute attrs =~ "phx-"
      refute attrs =~ ~r/\s(?:name|value|type|form|formaction|onclick)=/
      refute attrs =~ "outcome"
      refute html =~ ~r/<(?:button|input|form)\b/
    end

    # Mutation: carry the style whatever its shape - goes red.
    test "carries the style as a data attribute only where it is a string" do
      refute link_html(Map.delete(@lending_rules, "style")) =~ "data-riddler-style"
      refute link_html(%{@lending_rules | "style" => 2}) =~ "data-riddler-style"
      assert link_html(%{@lending_rules | "style" => "button"}) =~ ~s(data-riddler-style="button")
    end

    # Mutation: render the link whatever its label - goes red.
    test "renders nothing for a link with a blank label or no href" do
      assert link_html(%{@lending_rules | "label" => " "}) == ""
      assert link_html(Map.delete(@lending_rules, "href")) == ""
    end

    # Mutation: draw a host-relative href as an absolute one - goes red.
    test "draws a host-relative href as riddler presents it" do
      assert link_html(%{@lending_rules | "href" => "/branches/riverside"}) =~
               ~s(href="/branches/riverside")
    end

    # Mutation: render the label with raw/1 - goes red.
    test "escapes the label and the href" do
      html = link_html(%{@lending_rules | "label" => "<b>Rules</b>", "href" => "/r?a=1&b=2"})
      refute html =~ "<b>"
      assert html =~ "&lt;b&gt;Rules&lt;/b&gt;"
      assert html =~ ~s(href="/r?a=1&amp;b=2")
    end

    # Mutation: drop @class from the link's class list - goes red.
    test "adds a host's classes to its own" do
      assert link_html(@lending_rules, "rules") =~ ~s(class="riddler-link rules")
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

  describe "text_question/1 with a date or time format and a style" do
    @birth_date %{
      "type" => "text_question",
      "key" => "birth_date",
      "label" => "Date of birth",
      "format" => "date"
    }

    @pickup_time %{
      "type" => "text_question",
      "key" => "pickup_time",
      "label" => "Preferred pickup time",
      "format" => "time"
    }

    @holds %{
      "type" => "text_question",
      "key" => "holds_limit",
      "label" => "How many holds at once?",
      "format" => "integer",
      "style" => "slider",
      "min" => 1,
      "max" => 10
    }

    defp input_attrs(html) do
      assert [_, attrs] = Regex.run(~r{<input([^>]*)>}, html)
      attrs
    end

    # Mutation: answer "text" for the date format in input_type/2 - goes red.
    test "draws a date question as a date input with its presented bounds and value" do
      attrs =
        @birth_date
        |> Map.merge(%{"min" => "1900-01-01", "max" => "2026-11-26", "value" => "1990-05-04"})
        |> text_question_html()
        |> input_attrs()

      assert attrs =~ ~r/^ type="date"/
      assert attrs =~ ~s( value="1990-05-04")
      assert attrs =~ ~s( min="1900-01-01")
      assert attrs =~ ~s( max="2026-11-26")
      refute attrs =~ " step="
    end

    # Mutation: answer "text" for the time format in input_type/2 - goes red.
    test "draws a time question as a time input that moves by the minute" do
      attrs =
        @pickup_time
        |> Map.merge(%{"min" => "09:00", "max" => "17:30"})
        |> text_question_html()
        |> input_attrs()

      assert attrs =~ ~r/^ type="time"/
      assert attrs =~ ~s( min="09:00")
      assert attrs =~ ~s( max="17:30")
      refute attrs =~ " step="
    end

    # Mutation: answer nil from time_step/2 whatever the values - goes red.
    test "moves a time input by the second where its value or a bound carries seconds" do
      for extra <- [%{"value" => "10:15:30"}, %{"min" => "09:00:00"}, %{"max" => "17:30:00"}] do
        attrs = @pickup_time |> Map.merge(extra) |> text_question_html() |> input_attrs()
        assert attrs =~ ~s( step="1")
      end

      refute @pickup_time |> Map.put("value", "10:15:30.5") |> text_question_html() =~ " step="
    end

    # Mutation: copy a bound that is not a string onto a date input - goes red.
    test "draws no bound that is not text on a date or time input" do
      html =
        @birth_date |> Map.merge(%{"min" => 1900, "max" => " "}) |> text_question_html()

      refute html =~ ~r/\s(min|max)=/
    end

    # Mutation: draw the datetime format as a datetime-local input - goes red.
    test "draws a datetime question as the plain text input it was" do
      attrs =
        @birth_date
        |> Map.merge(%{"format" => "datetime", "min" => "2026-11-24T09:00:00-07:00"})
        |> text_question_html()
        |> input_attrs()

      assert attrs =~ ~r/^ type="text"/
      refute attrs =~ ~r/\s(min|max|step)=/
    end

    # Mutation: draw the multiline style as an input - goes red.
    test "draws a multiline question as a labelled textarea holding the presented value" do
      html =
        text_question_html(%{
          "type" => "text_question",
          "key" => "access_needs",
          "label" => "Anything we should know at the desk?",
          "style" => "multiline",
          "required" => true,
          "help" => "Optional.",
          "value" => "Step-free <entrance>"
        })

      refute html =~ "<input"

      assert html =~
               ~r{<textarea id="riddler-element-access_needs" name="access_needs" required aria-describedby="riddler-element-access_needs-help" class="riddler-input riddler-textarea" data-riddler-input>\nStep-free &lt;entrance&gt;</textarea>}

      assert html =~ ~s(data-riddler-style="multiline")
    end

    # Mutation: drop the newline textarea_value/1 opens the content on - goes red.
    test "keeps a presented value's own opening newline in a textarea" do
      element = %{
        "type" => "text_question",
        "key" => "access_needs",
        "label" => "Anything we should know at the desk?",
        "style" => "multiline"
      }

      assert text_question_html(Map.put(element, "value", "\nStep-free entrance")) =~
               ~r{data-riddler-input>\n\nStep-free entrance</textarea>}

      assert text_question_html(element) =~ ~r{data-riddler-input>\n</textarea>}
    end

    # Mutation: answer :multiline for the style whatever the format - goes red.
    test "draws a multiline question under a pattern as a textarea, and under another format as its input" do
      assert text_question_html(
               %{@email | "format" => "pattern"}
               |> Map.put("style", "multiline")
             ) =~
               "<textarea"

      for {format, type} <- [{"email", "email"}, {"date", "date"}, {"integer", "text"}] do
        html = text_question_html(%{@email | "format" => format} |> Map.put("style", "multiline"))
        refute html =~ "<textarea"
        assert html =~ ~s(<input type="#{type}")
      end
    end

    # Mutation: drop min and max from the slider's input - goes red.
    test "draws a slider as a range input with its bounds and step" do
      attrs =
        @holds |> Map.merge(%{"step" => 3, "value" => 4}) |> text_question_html() |> input_attrs()

      assert attrs =~ ~r/^ type="range"/
      assert attrs =~ ~s( min="1")
      assert attrs =~ ~s( max="10")
      assert attrs =~ ~s( step="3")
      assert attrs =~ ~s( value="4")
    end

    # Mutation: draw a slider whatever its bounds - goes red.
    test "draws a slider missing a bound, or under a format it does not read, as with no style" do
      for element <- [
            Map.delete(@holds, "max"),
            Map.put(@holds, "min", "1"),
            Map.put(@holds, "max", "10"),
            Map.put(@holds, "format", "email")
          ] do
        attrs = element |> text_question_html() |> input_attrs()
        refute attrs =~ ~s(type="range")
        refute attrs =~ ~r/\s(min|max|step)=/
      end
    end

    # Mutation: drop the "any" step for the number format - goes red.
    test "draws a stepper as a number input, by any step under number and by one under integer" do
      stepper = %{@holds | "style" => "stepper"} |> Map.delete("max")

      attrs = stepper |> text_question_html() |> input_attrs()
      assert attrs =~ ~r/^ type="number"/
      assert attrs =~ ~s( min="1")
      refute attrs =~ " max="
      refute attrs =~ " step="

      number = %{stepper | "format" => "number"} |> text_question_html() |> input_attrs()
      assert number =~ ~s( step="any")

      stepped = stepper |> Map.put("step", 0.5) |> Map.put("format", "number")
      assert stepped |> text_question_html() |> input_attrs() =~ ~s( step="0.5")

      assert stepper |> Map.put("step", 2) |> text_question_html() |> input_attrs() =~
               ~s( step="2")

      for step <- [0, -1, "2"] do
        refute stepper |> Map.put("step", step) |> text_question_html() =~ " step="
      end

      refute %{stepper | "format" => "pattern"} |> text_question_html() =~ ~s(type="number")
    end

    # Mutation: raise for a style the package does not draw - goes red.
    test "draws a style it does not draw, or one that is not text, as with no style" do
      for style <- ["carousel", 7, nil] do
        html = text_question_html(Map.put(@email, "style", style))
        assert html =~ ~s(<input type="email")
        refute html =~ "<textarea"
      end

      assert text_question_html(Map.put(@email, "style", "carousel")) =~
               ~s(data-riddler-style="carousel")

      refute text_question_html(Map.put(@email, "style", 7)) =~ "data-riddler-style"
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
      assert attrs =~ ~s( name="riddler-password[card_pin]")
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

  describe "choice_question/1" do
    @card_type %{
      "type" => "choice_question",
      "key" => "card_type",
      "label" => "Which library card would you like?",
      "select" => "one",
      "answer_options" => [
        %{"value" => "adult", "label" => "Adult card"},
        %{"value" => "child", "label" => "Child card"}
      ]
    }

    @branches %{
      "type" => "choice_question",
      "key" => "pickup_branches",
      "label" => "Where may we send your holds?",
      "select" => "many",
      "answer_options" => [
        %{"value" => "riverside", "label" => "Riverside"},
        %{"value" => "hillcrest", "label" => "Hillcrest"},
        %{"value" => "old_town", "label" => "Old Town"}
      ]
    }

    defp choice_html(element, attrs \\ %{}) do
      assigns = Map.merge(%{element: element, name: nil, class: nil}, attrs)

      rendered_to_string(
        ~H"<Components.choice_question element={@element} name={@name} class={@class} />"
      )
    end

    defp inputs(html), do: Regex.scan(~r{<input([^>]*)>}, html, capture: :all_but_first)

    # Mutation: render the question in a <div> with a <p> for its label - goes red.
    test "sits the options in a fieldset whose legend is the label" do
      html = choice_html(@card_type)

      assert html =~
               ~r{^<fieldset class="riddler-choice-question" data-riddler-element="choice_question" data-riddler-key="card_type" data-riddler-select="one">}

      assert html =~
               ~r{<legend id="riddler-element-card_type-legend" class="riddler-legend" data-riddler-legend>Which library card would you like\?</legend>}

      assert html =~ ~r{</fieldset>$}
    end

    # Mutation: draw a checkbox under "one" - goes red.
    test "draws a labelled radio button per option under one" do
      html = choice_html(@card_type)

      assert [[adult], [child]] = inputs(html)

      for {attrs, value} <- [{adult, "adult"}, {child, "child"}] do
        assert attrs =~ ~s( type="radio")
        assert attrs =~ ~s( id="riddler-element-card_type-option-#{value}")
        assert attrs =~ ~s( name="card_type")
        assert attrs =~ ~s( value="#{value}")
        assert attrs =~ ~s( class="riddler-input")
      end

      assert html =~
               ~r{<div class="riddler-option" data-riddler-option="child">\s*<input[^>]*>\s*<label for="riddler-element-card_type-option-child" class="riddler-label" data-riddler-label>Child card</label>}
    end

    # Mutation: draw a radio button under "many" - goes red.
    test "draws a checkbox per option under many, named for a list" do
      html = choice_html(@branches)

      assert html =~ ~s(data-riddler-select="many")
      assert [_, _, _] = rows = inputs(html)

      for [attrs] <- rows do
        assert attrs =~ ~s( type="checkbox")
        assert attrs =~ ~s( name="pickup_branches[]")
      end
    end

    # Mutation: compare the presented value with each option's label - goes red.
    test "draws the presented value chosen under one, and nothing for another shape" do
      assert [[adult], [child]] = inputs(choice_html(Map.put(@card_type, "value", "child")))
      refute adult =~ "checked"
      assert child =~ " checked"

      for value <- [nil, ["child"], "teen", 1] do
        refute choice_html(Map.put(@card_type, "value", value)) =~ "checked"
      end
    end

    # Mutation: read only the list's first value under "many" - goes red.
    test "draws every presented value chosen under many" do
      html = choice_html(Map.put(@branches, "value", ["riverside", "old_town"]))
      assert [[riverside], [hillcrest], [old_town]] = inputs(html)
      assert riverside =~ " checked"
      refute hillcrest =~ "checked"
      assert old_town =~ " checked"

      refute choice_html(Map.put(@branches, "value", "riverside")) =~ "checked"
    end

    # Mutation: mark the inputs required whatever the select - goes red.
    test "marks the radio buttons required where the question is, and no checkbox" do
      for [attrs] <- inputs(choice_html(Map.put(@card_type, "required", true))) do
        assert attrs =~ ~r/ required( |$)/
      end

      refute choice_html(@card_type) =~ "required"
      refute choice_html(Map.put(@branches, "required", true)) =~ "required"
    end

    # Mutation: carry the bounds whatever the select - goes red.
    test "carries the bounds under many as data attributes, and nowhere else" do
      bounded = Map.merge(@branches, %{"min_selections" => 1, "max_selections" => 2})
      html = choice_html(bounded)

      assert html =~ ~s(data-riddler-min-selections="1")
      assert html =~ ~s(data-riddler-max-selections="2")

      assert choice_html(Map.put(@branches, "min_selections", 0)) =~
               ~s(data-riddler-min-selections="0")

      refute html =~ ~r/\s(min|max)=/

      unbounded =
        choice_html(Map.merge(@card_type, %{"min_selections" => 1, "max_selections" => 2}))

      refute unbounded =~ "selections"

      refute choice_html(Map.merge(@branches, %{"min_selections" => "1", "max_selections" => -1})) =~
               "selections"
    end

    # Mutation: answer :inputs for every style in choice_drawn_as/2, or drop required from the select - goes red.
    test "draws a dropdown under one that opens on an empty option" do
      html = choice_html(Map.merge(@card_type, %{"style" => "dropdown", "value" => "adult"}))

      assert inputs(html) == []

      assert html =~
               ~r{<select id="riddler-element-card_type" name="card_type" aria-labelledby="riddler-element-card_type-legend" class="riddler-select" data-riddler-input>\s*<option value=""></option>}

      assert html =~
               ~r{<option value="adult" selected class="riddler-option" data-riddler-option="adult">\s*Adult card\s*</option>}

      assert html =~
               ~r{<option value="child" class="riddler-option" data-riddler-option="child">\s*Child card\s*</option>}

      refute html =~ "multiple"
      refute html =~ "required"

      required = Map.merge(@card_type, %{"style" => "dropdown", "required" => true})
      assert choice_html(required) =~ ~r{<select [^>]* required[ >]}
    end

    # Mutation: drop multiple={@many} from the select - goes red.
    test "draws a list under many as a multiple select with no empty option" do
      html = choice_html(Map.merge(@branches, %{"style" => "list", "value" => ["hillcrest"]}))

      assert html =~
               ~r{<select id="riddler-element-pickup_branches" name="pickup_branches\[\]" multiple aria-labelledby="riddler-element-pickup_branches-legend" class="riddler-select" data-riddler-input>}

      refute html =~ ~s(<option value="")
      assert html =~ ~r{<option value="hillcrest" selected }

      listed = Map.merge(@branches, %{"style" => "list", "required" => true})
      refute choice_html(listed) =~ "required"
    end

    # Mutation: draw a select for "dropdown" whatever the select - goes red.
    test "draws inputs for a style it does not draw, or one that names the other select" do
      for {element, type} <- [
            {Map.put(@card_type, "style", "chips"), "radio"},
            {Map.put(@card_type, "style", "list"), "radio"},
            {Map.put(@card_type, "style", "radio"), "radio"},
            {Map.put(@branches, "style", "dropdown"), "checkbox"},
            {Map.put(@branches, "style", "checkboxes"), "checkbox"}
          ] do
        html = choice_html(element)
        refute html =~ "<select"
        assert [[attrs] | _] = inputs(html)
        assert attrs =~ ~s( type="#{type}")
      end
    end

    # Mutation: render an option's label with raw/1 - goes red.
    test "escapes the legend and the option labels" do
      html =
        choice_html(%{
          @card_type
          | "label" => "<b>Card</b>",
            "answer_options" => [%{"value" => "adult", "label" => "<i>Adult</i>"}]
        })

      refute html =~ ~r/<[bi]>/
      assert html =~ "&lt;b&gt;Card&lt;/b&gt;"
      assert html =~ "&lt;i&gt;Adult&lt;/i&gt;"

      dropdown =
        choice_html(
          %{
            @card_type
            | "answer_options" => [%{"value" => "adult", "label" => "<i>Adult</i>"}]
          }
          |> Map.put("style", "dropdown")
        )

      refute dropdown =~ "<i>"
      assert dropdown =~ "&lt;i&gt;Adult&lt;/i&gt;"
    end

    # Mutation: drop aria-describedby from the fieldset - goes red.
    test "draws the help and names it as the fieldset's description" do
      html = choice_html(Map.put(@card_type, "help", "You can change it at the desk."))

      assert html =~
               ~r{^<fieldset [^>]*aria-describedby="riddler-element-card_type-help"}

      assert html =~
               ~r{<p id="riddler-element-card_type-help" class="riddler-help" data-riddler-help>You can change it at the desk.</p>}

      for help <- [nil, " "] do
        html = choice_html(Map.put(@card_type, "help", help))
        refute html =~ "riddler-help"
        refute html =~ "aria-describedby"
      end
    end

    # Mutation: ignore @name and always name the inputs by the key - goes red.
    test "names the inputs by the key unless the host passes a name" do
      assert choice_html(@card_type, %{name: "responses[card_type]"}) =~
               ~s(name="responses[card_type]")

      assert choice_html(@branches, %{name: "responses[pickup_branches]"}) =~
               ~s(name="responses[pickup_branches][]")
    end

    # Mutation: drop @class from the fieldset's class list - goes red.
    test "adds a host's classes to its own" do
      assert choice_html(@card_type, %{class: "cards"}) =~
               ~s(class="riddler-choice-question cards")
    end
  end

  describe "choice_question/1 with chips, searchable and option descriptions" do
    @card_kinds %{
      "type" => "choice_question",
      "key" => "card_type",
      "label" => "Which library card would you like?",
      "select" => "one",
      "answer_options" => [
        %{
          "value" => "adult",
          "label" => "Adult card",
          "description" => "For patrons of 18 and over."
        },
        %{"value" => "child", "label" => "Child card"}
      ]
    }

    # Mutation: drop the description id from the option input's aria-describedby - goes red.
    test "draws an option's description under its label and names it from its input" do
      html = choice_html(@card_kinds)

      assert [[adult], [child]] = inputs(html)
      assert adult =~ ~s( aria-describedby="riddler-element-card_type-option-adult-description")
      refute child =~ "aria-describedby"

      assert html =~
               ~r{<label for="riddler-element-card_type-option-adult" class="riddler-label" data-riddler-label>Adult card</label>\s*<p id="riddler-element-card_type-option-adult-description" class="riddler-option-description" data-riddler-option-description="adult">\s*For patrons of 18 and over.\s*</p>}
    end

    # Mutation: name the description ahead of the findings - goes red.
    test "names an option's findings ahead of its description" do
      findings = [%{"code" => "response.required", "element_key" => "card_type"}]
      assigns = %{element: @card_kinds, findings: findings}

      html =
        rendered_to_string(
          ~H"<Components.choice_question element={@element} findings={@findings} />"
        )

      assert [[adult] | _] = inputs(html)

      assert adult =~
               ~s( aria-describedby="riddler-element-card_type-finding-1 riddler-element-card_type-option-adult-description")
    end

    # Mutation: drop aria-describedby from the select's options - goes red.
    test "lists the descriptions after a select, each named by its option" do
      html = choice_html(Map.put(@card_kinds, "style", "dropdown"))

      assert html =~
               ~r{<option value="adult" class="riddler-option" data-riddler-option="adult" aria-describedby="riddler-element-card_type-option-adult-description">}

      assert html =~
               ~r{<dl class="riddler-option-descriptions" data-riddler-option-descriptions>\s*<dt class="riddler-option-label">Adult card</dt>\s*<dd id="riddler-element-card_type-option-adult-description" class="riddler-option-description" data-riddler-option-description="adult">\s*For patrons of 18 and over.\s*</dd>\s*</dl>}

      refute choice_html(Map.put(@card_type, "style", "dropdown")) =~ "<dl"
    end

    # Mutation: draw a select for chips - goes red.
    test "draws chips as the select's own inputs, each marked a chip" do
      for {element, type} <- [
            {Map.put(@card_kinds, "style", "chips"), "radio"},
            {Map.put(@branches, "style", "chips"), "checkbox"}
          ] do
        html = choice_html(element)

        refute html =~ "<select"
        assert html =~ ~s(data-riddler-style="chips")
        assert [[attrs] | _] = inputs(html)
        assert attrs =~ ~s( type="#{type}")
        assert [_ | _] = Regex.scan(~r/<div class="riddler-option riddler-chip"/, html)
      end

      refute choice_html(@card_kinds) =~ "riddler-chip"
    end

    # Mutation: answer :inputs for searchable in choice_drawn_as/3 - goes red.
    test "draws a searchable question under one as a text input bound to a datalist" do
      html =
        choice_html(
          Map.merge(@card_kinds, %{"searchable" => true, "required" => true, "value" => "child"})
        )

      assert html =~ ~s(data-riddler-searchable="true")
      assert [[attrs]] = inputs(html)
      assert attrs =~ ~r/^ type="text"/
      assert attrs =~ ~s( id="riddler-element-card_type")
      assert attrs =~ ~s( name="card_type")
      assert attrs =~ ~s( value="child")
      assert attrs =~ ~s( list="riddler-element-card_type-options")
      assert attrs =~ ~s( required)
      assert attrs =~ ~s( aria-labelledby="riddler-element-card_type-legend")

      assert html =~
               ~r{<datalist id="riddler-element-card_type-options" class="riddler-options">\s*<option value="adult" aria-describedby="riddler-element-card_type-option-adult-description" class="riddler-option" data-riddler-option="adult">\s*Adult card\s*</option>}

      assert html =~ ~s(<dd id="riddler-element-card_type-option-adult-description")

      for style <- ["dropdown", "chips"] do
        styled = choice_html(Map.merge(@card_kinds, %{"searchable" => true, "style" => style}))
        assert styled =~ "<datalist"
        refute styled =~ "<select"
        refute styled =~ "riddler-chip"
      end
    end

    # Mutation: draw the datalist under many - goes red.
    test "draws a searchable question under many, and one not searchable, as without the hint" do
      many = choice_html(Map.put(@branches, "searchable", true))
      refute many =~ "<datalist"
      assert [_, _, _] = inputs(many)
      assert many =~ ~s(data-riddler-searchable="true")

      for searchable <- [false, "true", nil] do
        html = choice_html(Map.put(@card_kinds, "searchable", searchable))
        refute html =~ "<datalist"
        refute html =~ "data-riddler-searchable"
      end
    end
  end

  describe "boolean_question/1" do
    @rules %{
      "type" => "boolean_question",
      "key" => "agrees_to_rules",
      "label" => "I agree to the borrowing rules."
    }

    defp boolean_html(element, attrs \\ %{}) do
      assigns = Map.merge(%{element: element, name: nil, class: nil}, attrs)

      rendered_to_string(
        ~H"<Components.boolean_question element={@element} name={@name} class={@class} />"
      )
    end

    # Mutation: render the input as type="radio" - goes red.
    test "renders a lone labelled checkbox that submits true" do
      html = boolean_html(@rules)

      assert html =~
               ~r{^<div class="riddler-boolean-question" data-riddler-element="boolean_question" data-riddler-key="agrees_to_rules">}

      assert html =~
               ~r{<label for="riddler-element-agrees_to_rules" class="riddler-label" data-riddler-label>I agree to the borrowing rules.</label>}

      refute html =~ "<fieldset"
      assert [_, attrs] = Regex.run(~r{<input([^>]*)>}, html)
      assert attrs =~ ~s( type="checkbox")
      assert attrs =~ ~s( id="riddler-element-agrees_to_rules")
      assert attrs =~ ~s( name="agrees_to_rules")
      assert attrs =~ ~s( value="true")
      assert attrs =~ ~s( class="riddler-input")
    end

    # Mutation: tick the box for any truthy value - goes red.
    test "ticks the box only where the answer presents true" do
      assert boolean_html(Map.put(@rules, "value", true)) =~ ~r{<input[^>]* checked[ >]}

      for value <- [false, nil, "true", 1] do
        refute boolean_html(Map.put(@rules, "value", value)) =~ "checked"
      end
    end

    # Mutation: render required whatever the element says - goes red.
    test "marks the checkbox required only where the question is" do
      assert boolean_html(Map.put(@rules, "required", true)) =~ ~r{<input[^>]* required[ >]}
      refute boolean_html(Map.put(@rules, "required", false)) =~ "required"
      refute boolean_html(@rules) =~ "required"
    end

    # Mutation: drop aria-describedby from the checkbox - goes red.
    test "draws the help and names it as the checkbox's description" do
      html = boolean_html(Map.put(@rules, "help", "Up to twelve items at a time."))

      assert html =~ ~s(aria-describedby="riddler-element-agrees_to_rules-help")

      assert html =~
               ~r{<p id="riddler-element-agrees_to_rules-help" class="riddler-help" data-riddler-help>Up to twelve items at a time.</p>}

      refute boolean_html(Map.put(@rules, "help", " ")) =~ "aria-describedby"
    end

    # Mutation: render the label with raw/1 - goes red.
    test "escapes the label" do
      html = boolean_html(%{@rules | "label" => "<b>I agree</b>"})
      refute html =~ "<b>"
      assert html =~ "&lt;b&gt;I agree&lt;/b&gt;"
    end

    # Mutation: ignore @name and always name the input by its key - goes red.
    test "names the checkbox by the key unless the host passes a name" do
      assert boolean_html(@rules, %{name: "responses[agrees_to_rules]"}) =~
               ~s(name="responses[agrees_to_rules]")
    end

    # Mutation: drop @class from the question's class list - goes red.
    test "adds a host's classes to its own" do
      assert boolean_html(@rules, %{class: "consent"}) =~
               ~s(class="riddler-boolean-question consent")
    end
  end

  describe "button/1" do
    @continue %{
      "type" => "button",
      "key" => "details_continue",
      "label" => "Continue",
      "outcome" => "details_submitted",
      "style" => "primary"
    }
    @go_back %{
      "type" => "button",
      "key" => "details_back",
      "label" => "Change card type",
      "outcome" => "card_type_changed",
      "validates" => false
    }
    @moves %{"outcomes" => ["details_submitted", "card_type_changed"], "back" => false}

    defp button_html(element, moves \\ @moves, class \\ nil) do
      assigns = %{element: element, moves: moves, class: class}

      rendered_to_string(
        ~H"<Components.button element={@element} moves={@moves} class={@class} />"
      )
    end

    # Mutation: name the button "action" instead of "outcome" - goes red.
    test "renders a submit button whose name and value carry the outcome" do
      html = button_html(@continue)

      assert html =~ ~r{^<button [^>]*>\s*Continue\s*</button>$}
      assert [_, attrs] = Regex.run(~r{<button([^>]*)>}, html)
      assert attrs =~ ~s( type="submit")
      assert attrs =~ ~s( name="outcome")
      assert attrs =~ ~s( value="details_submitted")
      assert attrs =~ ~s( class="riddler-button")
      assert attrs =~ ~s( data-riddler-element="button")
      assert attrs =~ ~s( data-riddler-key="details_continue")
      assert attrs =~ ~s( data-riddler-outcome="details_submitted")
    end

    # Mutation: draw the button whatever the moves list - goes red.
    test "draws a button only where the moves list its outcome" do
      for moves <- [
            %{"outcomes" => ["card_type_changed"], "back" => false},
            %{"outcomes" => [], "back" => true},
            %{"back" => false}
          ] do
        assert button_html(@continue, moves) == ""
      end

      assert button_html(Map.delete(@continue, "outcome")) == ""
    end

    # Mutation: drop formnovalidate from the button - goes red.
    test "a button that does not validate carries formnovalidate and says so" do
      assert [_, attrs] = Regex.run(~r{<button([^>]*)>}, button_html(@go_back))
      assert attrs =~ ~r/\sformnovalidate(?=\s|\z)/
      assert attrs =~ ~s( data-riddler-validates="false")
    end

    # Mutation: validate only where the button says validates true - goes red.
    test "a button that validates, by default or by saying so, carries no formnovalidate" do
      for element <- [@continue, Map.put(@continue, "validates", true)] do
        html = button_html(element)
        refute html =~ "formnovalidate"
        assert html =~ ~s( data-riddler-validates="true")
      end
    end

    # Mutation: render the style as a class - goes red.
    test "carries the style as a data attribute and nothing else" do
      html = button_html(@continue)
      assert html =~ ~s( data-riddler-style="primary")
      assert html =~ ~s( class="riddler-button")
      refute button_html(@go_back) =~ "data-riddler-style"
      refute button_html(Map.put(@continue, "style", 3)) =~ "data-riddler-style"
    end

    # Mutation: render the label with raw/1 - goes red.
    test "escapes the label" do
      html = button_html(%{@continue | "label" => "<b>Continue</b>"})
      refute html =~ "<b>"
      assert html =~ "&lt;b&gt;Continue&lt;/b&gt;"
    end

    # Mutation: drop @class from the button's class list - goes red.
    test "adds a host's classes to its own" do
      assert button_html(@continue, @moves, "primary-action") =~
               ~s(class="riddler-button primary-action")
    end
  end

  describe "back/1" do
    @details_screen %{"key" => "patron_details", "title" => "Your details", "elements" => []}

    defp back_html(moves, attrs \\ %{}) do
      assigns =
        Map.merge(
          %{
            screen: @details_screen,
            moves: moves,
            label: "Back",
            event: "back",
            target: nil,
            class: nil
          },
          attrs
        )

      rendered_to_string(~H"""
      <Components.back
        screen={@screen}
        moves={@moves}
        label={@label}
        event={@event}
        target={@target}
        class={@class}
      />
      """)
    end

    defp pushed(html) do
      [_, json] = Regex.run(~r{phx-click="([^"]*)"}, html)

      json
      |> String.replace("&quot;", "\"")
      |> String.replace("&amp;", "&")
      |> Jason.decode!()
    end

    # Mutation: draw Back whatever the moves say - goes red.
    test "draws Back only where the moves say back is true" do
      for back <- [false, nil, "true"] do
        assert back_html(%{"outcomes" => [], "back" => back}) == ""
      end

      assert back_html(%{"outcomes" => []}) == ""
      assert back_html(%{"outcomes" => [], "back" => true}) =~ "Back"
    end

    # Mutation: make Back a submit button - goes red.
    test "renders a button that submits no form" do
      html = back_html(%{"outcomes" => [], "back" => true})

      assert html =~ ~r{^<button [^>]*>\s*Back\s*</button>$}
      assert [_, attrs] = Regex.run(~r{<button([^>]*)>}, html)
      assert attrs =~ ~s( type="button")
      assert attrs =~ ~s( class="riddler-back")
      assert attrs =~ ~r/\sdata-riddler-back(?=\s|\z)/
      refute attrs =~ "name="
      refute attrs =~ "data-riddler-element"
    end

    # Mutation: push "back" as the string "true" - goes red.
    test "pushes riddler's back request, which riddler decodes as one" do
      html = back_html(%{"outcomes" => ["details_submitted"], "back" => true})

      assert [["push", %{"event" => "back", "value" => value} = push]] = pushed(html)
      refute Map.has_key?(push, "target")
      assert value == %{"screen" => "patron_details", "back" => true}

      # LiveView adds the button's own empty value to the params.
      assert Riddler.Journey.decode_submit(Map.put(value, "value", "")) ==
               {:ok, %{"screen" => "patron_details", "back" => true}}
    end

    # Mutation: ignore @event and @target and always push "back" to the LiveView - goes red.
    test "pushes the event a host names to the target it names" do
      html =
        back_html(%{"outcomes" => [], "back" => true}, %{
          event: "journey_back",
          target: "#journey"
        })

      assert [["push", %{"event" => "journey_back", "target" => "#journey"}]] = pushed(html)

      myself = %Phoenix.LiveComponent.CID{cid: 3}
      html = back_html(%{"outcomes" => [], "back" => true}, %{target: myself})
      assert [["push", %{"event" => "back", "target" => 3}]] = pushed(html)
    end

    # Mutation: ignore @label - goes red.
    test "draws the label a host passes, escaped" do
      html = back_html(%{"outcomes" => [], "back" => true}, %{label: "<i>Previous</i>"})
      assert html =~ "&lt;i&gt;Previous&lt;/i&gt;"
      refute html =~ "<i>"
    end

    # Mutation: drop @class from the control's class list - goes red.
    test "adds a host's classes to its own" do
      assert back_html(%{"outcomes" => [], "back" => true}, %{class: "secondary"}) =~
               ~s(class="riddler-back secondary")
    end
  end
end
