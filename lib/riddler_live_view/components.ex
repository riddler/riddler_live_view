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
      `heading/1` and `text/1`.

  The markup ships no stylesheet and no CSS framework class. Every component
  carries a `class` attribute, and a host may add its own classes through
  the `class` attribute each component takes. Every component also carries
  stable `data-riddler-*` attributes a host's stylesheet and tests can
  select on:

    * `data-riddler-element` on the markup of each element, whose value is
      the element's kind, the `"type"` the answer gives it (`"heading"`,
      `"text"`);
    * `data-riddler-key` on the markup of each element, whose value is the
      element's `"key"`;
    * `data-riddler-screen` on the frame, whose value is the screen's
      `"key"`;
    * `data-riddler-title`, `data-riddler-progress` and
      `data-riddler-elements` on the frame's title, progress and the
      container its elements render in.

  ## Example

  A patron registration's details screen, from the answer riddler gives:

      <RiddlerLiveView.Components.frame screen={@answer["screen"]} progress={@answer["progress"]}>
        <RiddlerLiveView.Components.heading element={heading} />
        <RiddlerLiveView.Components.text element={text} />
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
