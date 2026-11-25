defmodule RiddlerLiveView.Components do
  @moduledoc """
  Function components for a presented screen and its elements.

  `Riddler.Journey.present/3` answers a step of a Journey as data. For a
  screen, the answer's `"screen"` carries the screen's `"key"`, its
  `"title"` and its `"elements"`, and the answer carries `"progress"` only
  where the host supplied it. The components here render that data as plain
  semantic HTML:

    * `frame/1` draws the screen around its elements: the title, and
      progress when the answer carries it.
    * One component per element kind, named for the kind it renders:
      `heading/1`, `text/1`, `text_question/1` and `secret_question/1`.

  The markup ships no stylesheet and no CSS framework class. Every component
  carries a `class` attribute, and a host may add its own classes through
  the `class` attribute each component takes. Every component also carries
  stable `data-riddler-*` attributes a host's stylesheet and tests can
  select on:

    * `data-riddler-element` on the markup of each element, whose value is
      the element's kind, the `"type"` the answer gives it (`"heading"`,
      `"text"`, `"text_question"`, `"secret_question"`);
    * `data-riddler-key` on the markup of each element, whose value is the
      element's `"key"`;
    * `data-riddler-screen` on the frame, whose value is the screen's
      `"key"`;
    * `data-riddler-title`, `data-riddler-progress` and
      `data-riddler-elements` on the frame's title, progress and the
      container its elements render in;
    * `data-riddler-label`, `data-riddler-input`, `data-riddler-help` and
      `data-riddler-held` on a question's label, its input, its help and
      the paragraph that says a secret question's value is held.

  A secret question's input never carries a value: no `value` attribute,
  whatever the element carries, and `autocomplete="off"`.

  ## Example

  A patron registration's details screen, from the answer riddler gives:

      <RiddlerLiveView.Components.frame screen={@answer["screen"]} progress={@answer["progress"]}>
        <RiddlerLiveView.Components.heading element={heading} />
        <RiddlerLiveView.Components.text element={text} />
        <RiddlerLiveView.Components.text_question element={email} />
      </RiddlerLiveView.Components.frame>
  """

  use Phoenix.Component

  @doc """
  Draws a presented screen around its elements.

  The screen is a `<section>`. Its title, when the screen has one, is the
  section's `<h1>` and labels the section. Progress is drawn only when
  `progress` is given, as a `<progress>` whose value is the step and whose
  maximum is the number of steps; the package counts no steps itself. The
  elements render inside the frame's inner block.

  The title's `id` is derived from the screen's `"key"`, so a page that
  draws two frames of the same screen at once carries the id twice.
  """
  attr(:screen, :map,
    required: true,
    doc: "The answer's `\"screen\"`: its `\"key\"` and its `\"title\"`, a string or nil."
  )

  attr(:progress, :map,
    default: nil,
    doc:
      "The answer's `\"progress\"`, `\"step\"` of `\"of\"`, or nil where the host supplied none."
  )

  attr(:progress_label, :string,
    default: "Progress",
    doc: "The accessible name of the progress bar."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the frame's own.")

  slot(:inner_block, required: true, doc: "The screen's elements.")

  @spec frame(map()) :: Phoenix.LiveView.Rendered.t()
  def frame(assigns) do
    assigns =
      assign(assigns,
        title: present_text(assigns.screen["title"]),
        title_id: "riddler-screen-#{assigns.screen["key"]}-title"
      )

    ~H"""
    <section
      class={["riddler-screen" | List.wrap(@class)]}
      data-riddler-screen={@screen["key"]}
      aria-labelledby={@title && @title_id}
    >
      <h1 :if={@title} id={@title_id} class="riddler-screen-title" data-riddler-title>
        {@title}
      </h1>
      <progress
        :if={@progress}
        class="riddler-progress"
        data-riddler-progress
        value={@progress["step"]}
        max={@progress["of"]}
        aria-label={@progress_label}
      >
        {@progress["step"]} / {@progress["of"]}
      </progress>
      <div class="riddler-elements" data-riddler-elements>
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  @doc """
  Renders a `heading` element as the HTML heading of its `"level"`, `<h1>`
  to `<h6>`.

  A heading whose text is empty renders nothing: an empty heading names no
  section and is read out as a bare heading.

  Raises `ArgumentError` for a level outside 1 to 6, which riddler never
  presents.
  """
  attr(:element, :map,
    required: true,
    doc: "A `heading` element of the answer: its `\"key\"`, `\"level\"` and `\"text\"`."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the heading's own.")

  @spec heading(map()) :: Phoenix.LiveView.Rendered.t()
  def heading(assigns) do
    assigns =
      assign(assigns,
        tag: heading_tag(assigns.element["level"]),
        text: present_text(assigns.element["text"])
      )

    ~H"""
    <.dynamic_tag
      :if={@text}
      tag_name={@tag}
      class={["riddler-heading" | List.wrap(@class)]}
      data-riddler-element="heading"
      data-riddler-key={@element["key"]}
    >
      {@text}
    </.dynamic_tag>
    """
  end

  @doc """
  Renders a `text` element as a paragraph.
  """
  attr(:element, :map,
    required: true,
    doc: "A `text` element of the answer: its `\"key\"` and `\"text\"`."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the paragraph's own.")

  @spec text(map()) :: Phoenix.LiveView.Rendered.t()
  def text(assigns) do
    ~H"""
    <p
      class={["riddler-text" | List.wrap(@class)]}
      data-riddler-element="text"
      data-riddler-key={@element["key"]}
    >
      {@element["text"]}
    </p>
    """
  end

  @doc """
  Renders a `text_question` element as a labelled text input.

  The question's `"label"` is the input's `<label>`. Its `"help"`, when it
  has one, is a paragraph the input names as its description. The input
  carries the question's `"placeholder"`, and `required` where the question
  is required. The value the answer presents for the question, a response
  the visitor already gave or its prefill or default, is the input's
  `value`; a presented value that is not text or a number is not drawn.

  The `"format"` picks the input's `type`: `email` for `"email"`, `tel` for
  `"phone"`, and `text` for every other format and for none. The input
  carries no `pattern`, `min` or `max`: riddler validates what the visitor
  submits against the format, and the browser is not asked to.

  The input's `id` is derived from the question's `"key"`, and its `name`
  is the key unless the host passes one.
  """
  attr(:element, :map,
    required: true,
    doc:
      "A `text_question` element of the answer: its `\"key\"`, `\"label\"` and, where present, `\"help\"`, `\"placeholder\"`, `\"required\"`, `\"format\"` and `\"value\"`."
  )

  attr(:name, :string, default: nil, doc: "The input's `name`; the element's `\"key\"` when nil.")

  attr(:class, :any, default: nil, doc: "Classes added to the question's own.")

  @spec text_question(map()) :: Phoenix.LiveView.Rendered.t()
  def text_question(assigns) do
    key = assigns.element["key"]
    help = present_text(assigns.element["help"])

    assigns =
      assign(assigns,
        input_id: input_id(key),
        input_name: assigns.name || key,
        input_type: input_type(assigns.element["format"]),
        value: present_value(assigns.element["value"]),
        help: help,
        described_by: help && help_id(key)
      )

    ~H"""
    <div
      class={["riddler-text-question" | List.wrap(@class)]}
      data-riddler-element="text_question"
      data-riddler-key={@element["key"]}
    >
      <label for={@input_id} class="riddler-label" data-riddler-label>{@element["label"]}</label>
      <input
        type={@input_type}
        id={@input_id}
        name={@input_name}
        value={@value}
        placeholder={@element["placeholder"]}
        required={@element["required"] == true}
        aria-describedby={@described_by}
        class="riddler-input"
        data-riddler-input
      />
      <p :if={@help} id={@described_by} class="riddler-help" data-riddler-help>{@help}</p>
    </div>
    """
  end

  @doc """
  Renders a `secret_question` element as a labelled password input that
  never carries a value.

  The input has no `value` attribute, whatever the element carries, and sets
  `autocomplete="off"`, so nothing the visitor typed is drawn back into the
  page or offered again by the browser. riddler presents no value for a
  secret question, only `"held"`; where `"held"` is `true` a paragraph says
  a value is held, and the input names it as part of its description.

  The input carries `required` where the question is required and no value
  is held: a held value already satisfies `required` in riddler's
  validation. The question's `"help"`, when it has one, is a paragraph the
  input names as its description too.

  The input's `id` is derived from the question's `"key"`, and its `name`
  is the key unless the host passes one.
  """
  attr(:element, :map,
    required: true,
    doc:
      "A `secret_question` element of the answer: its `\"key\"`, `\"label\"` and `\"held\"` and, where present, `\"help\"` and `\"required\"`."
  )

  attr(:name, :string, default: nil, doc: "The input's `name`; the element's `\"key\"` when nil.")

  attr(:held_text, :string,
    default: "A value is held.",
    doc: "The text shown where a value is held."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the question's own.")

  @spec secret_question(map()) :: Phoenix.LiveView.Rendered.t()
  def secret_question(assigns) do
    key = assigns.element["key"]
    held = assigns.element["held"] == true
    help = present_text(assigns.element["help"])
    described = [held && held_id(key), help && help_id(key)] |> Enum.filter(& &1)

    assigns =
      assign(assigns,
        input_id: input_id(key),
        input_name: assigns.name || key,
        held: held,
        held_id: held_id(key),
        help: help,
        help_id: help_id(key),
        required: assigns.element["required"] == true and not held,
        described_by: if(described == [], do: nil, else: Enum.join(described, " "))
      )

    ~H"""
    <div
      class={["riddler-secret-question" | List.wrap(@class)]}
      data-riddler-element="secret_question"
      data-riddler-key={@element["key"]}
    >
      <label for={@input_id} class="riddler-label" data-riddler-label>{@element["label"]}</label>
      <input
        type="password"
        id={@input_id}
        name={@input_name}
        autocomplete="off"
        required={@required}
        aria-describedby={@described_by}
        class="riddler-input"
        data-riddler-input
      />
      <p :if={@held} id={@held_id} class="riddler-held" data-riddler-held>{@held_text}</p>
      <p :if={@help} id={@help_id} class="riddler-help" data-riddler-help>{@help}</p>
    </div>
    """
  end

  defp input_id(key), do: "riddler-element-#{key}"
  defp help_id(key), do: "riddler-element-#{key}-help"
  defp held_id(key), do: "riddler-element-#{key}-held"

  defp input_type("email"), do: "email"
  defp input_type("phone"), do: "tel"
  defp input_type(_format), do: "text"

  defp present_value(value) when is_binary(value) or is_number(value), do: value
  defp present_value(_value), do: nil

  defp heading_tag(level) when is_integer(level) and level in 1..6, do: "h#{level}"

  defp heading_tag(level) do
    raise ArgumentError,
          "a heading's \"level\" is an integer from 1 to 6, got: #{inspect(level)}"
  end

  defp present_text(text) when is_binary(text) do
    if String.trim(text) == "", do: nil, else: text
  end

  defp present_text(_text), do: nil
end
