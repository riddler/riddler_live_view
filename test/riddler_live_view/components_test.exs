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
end
