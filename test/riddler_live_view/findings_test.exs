defmodule RiddlerLiveView.FindingsTest do
  @moduledoc """
  Findings drawn beside the question they name, the frame's own findings, and
  the focus that moves to the first of them.
  """

  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias RiddlerLiveView.Components

  @email %{
    "type" => "text_question",
    "key" => "reminder_email",
    "label" => "Email for reminders",
    "format" => "email",
    "help" => "One reminder a week."
  }

  @pin %{
    "type" => "secret_question",
    "key" => "card_pin",
    "label" => "Library card PIN",
    "held" => true,
    "help" => "Four digits."
  }

  @card_type %{
    "type" => "choice_question",
    "key" => "card_type",
    "label" => "Which library card would you like?",
    "select" => "one",
    "help" => "Change it at the desk.",
    "answer_options" => [
      %{"value" => "adult", "label" => "Adult card"},
      %{"value" => "child", "label" => "Child card"}
    ]
  }

  @rules %{
    "type" => "boolean_question",
    "key" => "agrees_to_rules",
    "label" => "I agree to the borrowing rules.",
    "help" => "Twelve items at a time."
  }

  @continue %{
    "type" => "button",
    "key" => "details_continue",
    "label" => "Continue",
    "outcome" => "details_submitted"
  }

  @screen %{
    "key" => "patron_details",
    "title" => "Your details",
    "elements" => [@email, @card_type, @rules, @continue]
  }

  defp finding(code, element_key, author_message \\ nil) do
    %{
      "code" => code,
      "message" => "the package's sentence for #{code}",
      "field" => nil,
      "element_key" => element_key,
      "position" => nil,
      "author_message" => author_message
    }
  end

  defp question_html(component, element, findings, finding_text \\ %{}) do
    assigns = %{element: element, findings: findings, finding_text: finding_text}

    case component do
      :text_question ->
        rendered_to_string(~H"""
        <Components.text_question element={@element} findings={@findings} finding_text={@finding_text} />
        """)

      :secret_question ->
        rendered_to_string(~H"""
        <Components.secret_question element={@element} findings={@findings} finding_text={@finding_text} />
        """)

      :choice_question ->
        rendered_to_string(~H"""
        <Components.choice_question element={@element} findings={@findings} finding_text={@finding_text} />
        """)

      :boolean_question ->
        rendered_to_string(~H"""
        <Components.boolean_question element={@element} findings={@findings} finding_text={@finding_text} />
        """)
    end
  end

  defp frame_html(screen, findings) do
    assigns = %{screen: screen, findings: findings}

    rendered_to_string(~H"""
    <Components.frame screen={@screen} findings={@findings}>
      <span>the elements</span>
    </Components.frame>
    """)
  end

  defp finding_paragraphs(html) do
    Regex.scan(~r{<p([^>]*\bdata-riddler-finding[^>]*)>\s*(.*?)\s*</p>}s, html,
      capture: :all_but_first
    )
  end

  defp input_attrs(html),
    do: Regex.scan(~r{<(?:input|select)([^>]*)>}, html, capture: :all_but_first)

  defp focused(html) do
    [_, json] = Regex.run(~r{phx-mounted="([^"]*)"}, html)

    json
    |> String.replace("&quot;", "\"")
    |> String.replace("&amp;", "&")
    |> Jason.decode!()
  end

  describe "a question's findings" do
    # Mutation: drop aria-invalid={@invalid} from the text question's input - goes red.
    test "a text question draws its finding beside its input, which it marks invalid and names first" do
      html =
        question_html(:text_question, @email, [
          finding("response.format", "reminder_email", "Check the address, it looks incomplete.")
        ])

      assert [[attrs, "Check the address, it looks incomplete."]] = finding_paragraphs(html)
      assert attrs =~ ~s( id="riddler-element-reminder_email-finding-1")
      assert attrs =~ ~s( tabindex="-1")
      assert attrs =~ ~s( class="riddler-finding")
      assert attrs =~ ~s( data-riddler-finding="response.format")

      assert [[input]] = input_attrs(html)
      assert input =~ ~s( aria-invalid="true")

      assert input =~
               ~s( aria-describedby="riddler-element-reminder_email-finding-1 riddler-element-reminder_email-help")

      # Beside the input: after it and before the help.
      assert html =~ ~r{<input[^>]*>\s*<p id="riddler-element-reminder_email-finding-1"}s
    end

    # Mutation: draw every finding passed, whatever its element_key, in element_findings/2 - goes red.
    test "draws only the findings whose element_key is the question's key" do
      html =
        question_html(:text_question, @email, [
          finding("response.required", "card_type"),
          finding("submit.missing_field", nil),
          finding("response.format", "reminder_email")
        ])

      assert [[attrs, _text]] = finding_paragraphs(html)
      assert attrs =~ ~s( id="riddler-element-reminder_email-finding-1")
      assert attrs =~ ~s( data-riddler-finding="response.format")
    end

    # Mutation: leave aria-invalid="true" on the input whatever the findings - goes red.
    test "a question with no finding of its own is not marked invalid and draws no finding" do
      for findings <- [[], [finding("response.required", "card_type")]] do
        html = question_html(:text_question, @email, findings)

        refute html =~ "aria-invalid"
        refute html =~ "data-riddler-finding"
        assert html =~ ~s(aria-describedby="riddler-element-reminder_email-help")
      end
    end

    # Mutation: number every finding 1 in drawn_findings/3 - goes red.
    test "draws each finding of a question, numbered in order, and names them all" do
      html =
        question_html(:text_question, Map.delete(@email, "help"), [
          finding("response.required", "reminder_email"),
          finding("response.format", "reminder_email")
        ])

      assert [[first, _], [second, _]] = finding_paragraphs(html)
      assert first =~ ~s( id="riddler-element-reminder_email-finding-1")
      assert second =~ ~s( id="riddler-element-reminder_email-finding-2")

      assert html =~
               ~s(aria-describedby="riddler-element-reminder_email-finding-1 riddler-element-reminder_email-finding-2")
    end

    # Mutation: draw the finding's message where it has no author_message - goes red.
    test "draws the package's own text where the author wrote none, and never the message" do
      html =
        question_html(:text_question, @email, [
          finding("response.required", "reminder_email"),
          finding("response.format", "reminder_email", " "),
          finding("response.undecidable", "reminder_email")
        ])

      assert [[_, required], [_, format], [_, other]] = finding_paragraphs(html)
      assert required == "Answer this question."
      assert format == "This answer is not in the form asked for."
      assert other == "This could not be accepted."
      refute html =~ "the package&#39;s sentence"
      refute html =~ "the package's sentence"
    end

    # Mutation: ignore @finding_text in own_text/2 - goes red.
    test "draws a host's text for a code in place of the package's own, never over the author's" do
      html =
        question_html(
          :text_question,
          @email,
          [
            finding("response.required", "reminder_email"),
            finding("response.format", "reminder_email", "Check the address.")
          ],
          %{"response.required" => "Please give an email.", "response.format" => "Host text."}
        )

      assert [[_, "Please give an email."], [_, "Check the address."]] = finding_paragraphs(html)
    end

    # Mutation: read only string keys in finding_field/2 - goes red.
    test "takes a Riddler.Finding struct as it takes the wire form" do
      struct = %Riddler.Finding{
        code: "response.required",
        message: "the package's sentence for response.required",
        element_key: "reminder_email",
        author_message: "We need an address for reminders."
      }

      html = question_html(:text_question, @email, [struct])

      assert [[attrs, "We need an address for reminders."]] = finding_paragraphs(html)
      assert attrs =~ ~s( data-riddler-finding="response.required")
    end

    # Mutation: escape nothing, render the author's text with raw/1 - goes red.
    test "escapes the author's text" do
      html =
        question_html(:text_question, @email, [
          finding("response.format", "reminder_email", "<b>Check</b> it")
        ])

      refute html =~ "<b>"
      assert html =~ "&lt;b&gt;Check&lt;/b&gt; it"
    end

    # Mutation: drop aria-invalid={@invalid} from the secret question's input - goes red.
    test "a secret question names its finding ahead of what is held and its help" do
      html = question_html(:secret_question, @pin, [finding("response.required", "card_pin")])

      assert [[input]] = input_attrs(html)
      assert input =~ ~s( aria-invalid="true")

      assert input =~
               ~s( aria-describedby="riddler-element-card_pin-finding-1 riddler-element-card_pin-held riddler-element-card_pin-help")

      assert [[_, "Answer this question."]] = finding_paragraphs(html)
    end

    # Mutation: drop aria-invalid={@invalid} from the choice question's option inputs - goes red.
    test "a choice question marks each option input invalid and names the finding from its fieldset" do
      html =
        question_html(:choice_question, @card_type, [finding("response.required", "card_type")])

      assert [_, _] = inputs = input_attrs(html)
      assert Enum.all?(inputs, fn [attrs] -> attrs =~ ~s( aria-invalid="true") end)

      assert Enum.all?(inputs, fn [attrs] ->
               attrs =~ ~s( aria-describedby="riddler-element-card_type-finding-1")
             end)

      assert html =~
               ~r{^<fieldset [^>]*aria-describedby="riddler-element-card_type-finding-1 riddler-element-card_type-help"}

      assert [[_, "Answer this question."]] = finding_paragraphs(html)
    end

    # Mutation: drop aria-invalid={@invalid} from the choice question's select - goes red.
    # Mutation: name only the findings in the select's aria-describedby - goes red.
    test "a choice question drawn as a select marks the select invalid" do
      html =
        question_html(:choice_question, Map.put(@card_type, "style", "dropdown"), [
          finding("response.not_an_option", "card_type")
        ])

      assert [_, select] = Regex.run(~r{<select([^>]*)>}, html)
      assert select =~ ~s( aria-invalid="true")

      assert select =~
               ~s( aria-describedby="riddler-element-card_type-finding-1 riddler-element-card_type-help")

      assert [[_, "Choose from the options given."]] = finding_paragraphs(html)
    end

    # Mutation: drop aria-invalid={@invalid} from the boolean question's checkbox - goes red.
    test "a boolean question marks its checkbox invalid and names its finding" do
      html =
        question_html(:boolean_question, @rules, [finding("response.required", "agrees_to_rules")])

      assert [[input]] = input_attrs(html)
      assert input =~ ~s( aria-invalid="true")

      assert input =~
               ~s( aria-describedby="riddler-element-agrees_to_rules-finding-1 riddler-element-agrees_to_rules-help")
    end
  end

  describe "the frame's findings and focus" do
    # Mutation: reject no finding in frame/1, so the frame draws the questions' too - goes red.
    test "draws the findings that name no question of the screen, above the elements" do
      html =
        frame_html(@screen, [
          finding("response.required", "reminder_email"),
          finding("submit.missing_field", nil),
          finding("response.undecidable", "details_continue"),
          finding("response.required", "not_on_this_screen")
        ])

      assert [[first, _], [second, _], [third, _]] = finding_paragraphs(html)
      assert first =~ ~s( id="riddler-screen-patron_details-finding-1")
      assert first =~ ~s( data-riddler-finding="submit.missing_field")
      assert second =~ ~s( data-riddler-finding="response.undecidable")
      assert third =~ ~s( id="riddler-screen-patron_details-finding-3")
      refute html =~ "riddler-element-reminder_email-finding"

      assert html =~ ~r{data-riddler-finding="response.required"[^>]*>.*?</p>\s*<span[^>]*hidden}s
      assert html =~ ~r{</span>\s*<div class="riddler-elements"}s
    end

    # Mutation: drop aria-describedby={@described_by} from the frame's section - goes red.
    test "names its own findings as the section's description, and none where it draws none" do
      html =
        frame_html(@screen, [
          finding("submit.missing_field", nil),
          finding("response.required", "reminder_email"),
          finding("response.undecidable", "details_continue")
        ])

      assert html =~
               ~r{^<section [^>]*aria-describedby="riddler-screen-patron_details-finding-1 riddler-screen-patron_details-finding-2"}

      refute frame_html(@screen, [finding("response.required", "reminder_email")]) =~
               ~r{<section [^>]*aria-describedby}
    end

    # Mutation: drop the clause of first_finding_id/3 that takes the frame's own first - goes red.
    test "moves focus to the frame's own first finding where it draws one" do
      html =
        frame_html(@screen, [
          finding("response.required", "reminder_email"),
          finding("submit.missing_field", nil)
        ])

      assert [["focus", %{"to" => "#riddler-screen-patron_details-finding-1"}]] = focused(html)
      assert html =~ ~s(data-riddler-focus="riddler-screen-patron_details-finding-1")
      assert html =~ ~s(id="riddler-screen-patron_details-finding-1-focus")
    end

    # Mutation: take the first question in the findings' order, not the screen's - goes red.
    test "else moves focus to the first finding of the first question, in the screen's order" do
      html =
        frame_html(@screen, [
          finding("response.required", "agrees_to_rules"),
          finding("response.required", "card_type")
        ])

      assert [["focus", %{"to" => "#riddler-element-card_type-finding-1"}]] = focused(html)
      refute html =~ "data-riddler-finding="
    end

    # Mutation: draw the focus trigger whatever the findings - goes red.
    test "moves no focus where there is no finding" do
      for screen <- [@screen, %{@screen | "elements" => []}] do
        html = frame_html(screen, [])

        refute html =~ "phx-mounted"
        refute html =~ "data-riddler-focus"
        refute html =~ "data-riddler-finding"
      end

      assigns = %{screen: @screen}

      refute rendered_to_string(~H"""
             <Components.frame screen={@screen}><span>x</span></Components.frame>
             """) =~ "phx-mounted"
    end

    # Mutation: drop tabindex="-1" from finding_list/1 - goes red.
    test "the finding focus moves to can take focus and is a question's own" do
      assigns = %{
        screen: @screen,
        email: @email,
        findings: [finding("response.format", "reminder_email")]
      }

      html =
        rendered_to_string(~H"""
        <Components.frame screen={@screen} findings={@findings}>
          <Components.text_question element={@email} findings={@findings} />
        </Components.frame>
        """)

      assert [["focus", %{"to" => "#" <> target}]] = focused(html)
      assert [[attrs, _]] = finding_paragraphs(html)
      assert attrs =~ ~s( id="#{target}")
      assert attrs =~ ~s( tabindex="-1")
    end
  end
end
