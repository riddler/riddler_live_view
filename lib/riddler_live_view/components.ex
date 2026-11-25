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
      `heading/1`, `text/1`, `text_question/1`, `secret_question/1`,
      `choice_question/1`, `boolean_question/1` and `button/1`.
    * `back/1` draws the Back control where the answer's `"moves"` let the
      visitor go back.

  The markup ships no stylesheet and no CSS framework class. Every component
  carries a `class` attribute, and a host may add its own classes through
  the `class` attribute each component takes. Every component also carries
  stable `data-riddler-*` attributes a host's stylesheet and tests can
  select on:

    * `data-riddler-element` on the markup of each element, whose value is
      the element's kind, the `"type"` the answer gives it (`"heading"`,
      `"text"`, `"text_question"`, `"secret_question"`,
      `"choice_question"`, `"boolean_question"`, `"button"`);
    * `data-riddler-key` on the markup of each element, whose value is the
      element's `"key"`;
    * `data-riddler-screen` on the frame, whose value is the screen's
      `"key"`;
    * `data-riddler-title`, `data-riddler-progress` and
      `data-riddler-elements` on the frame's title, progress and the
      container its elements render in;
    * `data-riddler-label`, `data-riddler-input`, `data-riddler-help` and
      `data-riddler-held` on a question's label, its input, its help and
      the paragraph that says a secret question's value is held;
    * `data-riddler-legend` on a choice question's legend, and
      `data-riddler-option` on each of its options, whose value is the
      option's `"value"`;
    * `data-riddler-select` on a choice question, `"one"` or `"many"`, and
      `data-riddler-min-selections` and `data-riddler-max-selections`
      where it carries those bounds under `"many"`;
    * `data-riddler-outcome`, `data-riddler-validates` and
      `data-riddler-style` on a button, whose values are its `"outcome"`,
      `"true"` or `"false"` for whether it validates, and its `"style"`
      where it carries one;
    * `data-riddler-back` on the Back control.

  A secret question's input never carries a value: no `value` attribute,
  whatever the element carries, and `autocomplete="off"`.

  ## Example

  A patron registration's details screen, from the answer riddler gives:

      <RiddlerLiveView.Components.frame screen={@answer["screen"]} progress={@answer["progress"]}>
        <RiddlerLiveView.Components.heading element={heading} />
        <RiddlerLiveView.Components.text element={text} />
        <RiddlerLiveView.Components.text_question element={email} />
        <RiddlerLiveView.Components.button element={continue} moves={@answer["moves"]} />
        <RiddlerLiveView.Components.back screen={@answer["screen"]} moves={@answer["moves"]} />
      </RiddlerLiveView.Components.frame>
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

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

  @doc """
  Renders a `choice_question` element as a fieldset of options whose legend
  is the question's `"label"`.

  The question's `"select"` fixes what the visitor picks: one option under
  `"one"`, any number under `"many"`. Its `"style"` picks how the options are
  drawn, from the hints riddler names:

    * under `"one"`, `"radio"` draws a radio button per option and
      `"dropdown"` a `<select>` that opens on an empty option, which
      submits an empty value where the visitor chooses none;
    * under `"many"`, `"checkboxes"` draws a checkbox per option and
      `"list"` a `<select multiple>`;
    * no style, or a style the package does not draw, draws radio buttons
      under `"one"` and checkboxes under `"many"`.

  Each option's `"label"` is what the visitor reads and its `"value"` is
  what the input submits. The value the answer presents for the question, a
  response the visitor already gave or its prefill or default, is drawn
  chosen: under `"one"` the option whose value it is, under `"many"` every
  option whose value is in its list. A presented value of another shape
  chooses nothing.

  Under `"one"` the inputs carry `required` where the question is required.
  Under `"many"` nothing is marked `required`, since a required checkbox is
  one that must itself be ticked; the bounds riddler reads under `"many"`,
  `"min_selections"` and `"max_selections"`, are carried as the fieldset's
  `data-riddler-min-selections` and `data-riddler-max-selections` and are
  not enforced in the browser: riddler validates what the visitor submits
  against them.

  The question's `"help"`, when it has one, is a paragraph the fieldset
  names as its description. Each option input's `id` is derived from the
  question's `"key"` and the option's `"value"`, a `<select>`'s from the key
  alone, and the `name` is the key unless the host passes one; under
  `"many"` the name ends in `[]`, so the submitted params carry a list.
  """
  attr(:element, :map,
    required: true,
    doc:
      "A `choice_question` element of the answer: its `\"key\"`, `\"label\"`, `\"select\"` and `\"answer_options\"`, each a `\"value\"` and a `\"label\"`, and, where present, `\"help\"`, `\"required\"`, `\"style\"`, `\"min_selections\"`, `\"max_selections\"` and `\"value\"`."
  )

  attr(:name, :string,
    default: nil,
    doc: "The inputs' `name`; the element's `\"key\"` when nil, with `[]` added under `\"many\"`."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the question's own.")

  @spec choice_question(map()) :: Phoenix.LiveView.Rendered.t()
  def choice_question(assigns) do
    element = assigns.element
    key = element["key"]
    many = element["select"] == "many"
    help = present_text(element["help"])
    chosen = chosen_values(element["value"], many)

    options =
      for option <- List.wrap(element["answer_options"]) do
        %{
          value: option["value"],
          label: option["label"],
          id: option_id(key, option["value"]),
          chosen: option["value"] in chosen
        }
      end

    assigns =
      assign(assigns,
        options: options,
        many: many,
        drawn_as: choice_drawn_as(element["style"], many),
        legend_id: legend_id(key),
        select_id: input_id(key),
        input_name: choice_name(assigns.name || key, many),
        required: not many and element["required"] == true,
        min_selections: many && selection_bound(element["min_selections"]),
        max_selections: many && selection_bound(element["max_selections"]),
        help: help,
        described_by: help && help_id(key)
      )

    ~H"""
    <fieldset
      class={["riddler-choice-question" | List.wrap(@class)]}
      data-riddler-element="choice_question"
      data-riddler-key={@element["key"]}
      data-riddler-select={if(@many, do: "many", else: "one")}
      data-riddler-min-selections={@min_selections}
      data-riddler-max-selections={@max_selections}
      aria-describedby={@described_by}
    >
      <legend id={@legend_id} class="riddler-legend" data-riddler-legend>{@element["label"]}</legend>
      <div
        :for={option <- @options}
        :if={@drawn_as == :inputs}
        class="riddler-option"
        data-riddler-option={option.value}
      >
        <input
          type={if(@many, do: "checkbox", else: "radio")}
          id={option.id}
          name={@input_name}
          value={option.value}
          checked={option.chosen}
          required={@required}
          class="riddler-input"
          data-riddler-input
        />
        <label for={option.id} class="riddler-label" data-riddler-label>{option.label}</label>
      </div>
      <select
        :if={@drawn_as == :select}
        id={@select_id}
        name={@input_name}
        multiple={@many}
        required={@required}
        aria-labelledby={@legend_id}
        class="riddler-select"
        data-riddler-input
      >
        <option :if={not @many} value=""></option>
        <option
          :for={option <- @options}
          value={option.value}
          selected={option.chosen}
          class="riddler-option"
          data-riddler-option={option.value}
        >
          {option.label}
        </option>
      </select>
      <p :if={@help} id={@described_by} class="riddler-help" data-riddler-help>{@help}</p>
    </fieldset>
    """
  end

  @doc """
  Renders a `boolean_question` element as a lone labelled checkbox.

  The question's `"label"` is the checkbox's `<label>`, and the checkbox
  submits `"true"` when it is ticked; an unticked checkbox submits nothing.
  It is drawn ticked where the answer presents `true` for the question.

  The checkbox carries `required` where the question is required: riddler
  reads a required boolean question as one whose response must be `true`,
  which is what `required` asks of a checkbox. The question's `"help"`, when
  it has one, is a paragraph the checkbox names as its description.

  The checkbox's `id` is derived from the question's `"key"`, and its
  `name` is the key unless the host passes one.
  """
  attr(:element, :map,
    required: true,
    doc:
      "A `boolean_question` element of the answer: its `\"key\"` and `\"label\"` and, where present, `\"help\"`, `\"required\"` and `\"value\"`."
  )

  attr(:name, :string,
    default: nil,
    doc: "The checkbox's `name`; the element's `\"key\"` when nil."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the question's own.")

  @spec boolean_question(map()) :: Phoenix.LiveView.Rendered.t()
  def boolean_question(assigns) do
    key = assigns.element["key"]
    help = present_text(assigns.element["help"])

    assigns =
      assign(assigns,
        input_id: input_id(key),
        input_name: assigns.name || key,
        checked: assigns.element["value"] == true,
        required: assigns.element["required"] == true,
        help: help,
        described_by: help && help_id(key)
      )

    ~H"""
    <div
      class={["riddler-boolean-question" | List.wrap(@class)]}
      data-riddler-element="boolean_question"
      data-riddler-key={@element["key"]}
    >
      <input
        type="checkbox"
        id={@input_id}
        name={@input_name}
        value="true"
        checked={@checked}
        required={@required}
        aria-describedby={@described_by}
        class="riddler-input"
        data-riddler-input
      />
      <label for={@input_id} class="riddler-label" data-riddler-label>{@element["label"]}</label>
      <p :if={@help} id={@described_by} class="riddler-help" data-riddler-help>{@help}</p>
    </div>
    """
  end

  @doc """
  Renders a `button` element as a submit button that raises its outcome.

  The button is drawn only where the answer's `"moves"` lists its
  `"outcome"` among `"outcomes"`: a client reads what it may submit from the
  moves, never from the elements, so a button whose outcome the moves do not
  list is not drawn. Drawn, it is a `<button type="submit">` whose text is
  the button's `"label"` and whose `name` and `value` are `"outcome"` and the
  button's outcome, so the form it submits carries the outcome under the key
  riddler's submit names.

  A button whose `"validates"` is `false` does not validate the screen it
  submits: it carries `formnovalidate`, so the browser's own checks do not
  stop the press, and `data-riddler-validates="false"`, so the host knows to
  submit it without validating the responses. Every other button carries
  `data-riddler-validates="true"`, riddler's default. The submit names the
  outcome, not the button's key: in a document riddler validates, no two
  buttons a screen shows together raise one outcome, so the host finds the
  pressed button, and whether it validates, by its outcome. The button's
  `"style"`, a string from the open set riddler leaves to a renderer, is
  carried as `data-riddler-style` and drawn no differently.
  """
  attr(:element, :map,
    required: true,
    doc:
      "A `button` element of the answer: its `\"key\"`, `\"label\"` and `\"outcome\"` and, where present, `\"validates\"` and `\"style\"`."
  )

  attr(:moves, :map,
    required: true,
    doc: "The answer's `\"moves\"`: its `\"outcomes\"` and `\"back\"`."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the button's own.")

  @spec button(map()) :: Phoenix.LiveView.Rendered.t()
  def button(assigns) do
    outcome = assigns.element["outcome"]
    style = assigns.element["style"]

    assigns =
      assign(assigns,
        shown: is_binary(outcome) and outcome in List.wrap(assigns.moves["outcomes"]),
        validates: assigns.element["validates"] != false,
        style: if(is_binary(style), do: style)
      )

    ~H"""
    <button
      :if={@shown}
      type="submit"
      name="outcome"
      value={@element["outcome"]}
      formnovalidate={not @validates}
      class={["riddler-button" | List.wrap(@class)]}
      data-riddler-element="button"
      data-riddler-key={@element["key"]}
      data-riddler-outcome={@element["outcome"]}
      data-riddler-validates={to_string(@validates)}
      data-riddler-style={@style}
    >
      {@element["label"]}
    </button>
    """
  end

  @doc """
  Draws the Back control, only where the answer's `"moves"` say `"back"` is
  `true`.

  Back is not an element of the screen and raises no outcome: it is a
  `<button type="button">` that submits no form, so nothing the visitor
  entered on the screen is validated or sent. Pressed, it pushes `event`
  with riddler's back request as its value, `"screen"`, the key of the
  screen shown, and `"back"`, `true`, with no `"outcome"`; a host's
  LiveView, or the component named by `target`, handles the event and
  passes the request on. LiveView adds the button's own `"value"`, an empty
  string, to the params, and `Riddler.Journey.decode_submit/1` drops it.
  """
  attr(:screen, :map,
    required: true,
    doc: "The answer's `\"screen\"`: its `\"key\"` is the back request's `\"screen\"`."
  )

  attr(:moves, :map,
    required: true,
    doc: "The answer's `\"moves\"`: its `\"outcomes\"` and `\"back\"`."
  )

  attr(:label, :string, default: "Back", doc: "The control's text.")

  attr(:event, :string, default: "back", doc: "The event the control pushes.")

  attr(:target, :any,
    default: nil,
    doc:
      "Where the event is pushed: a LiveComponent's `@myself` or a selector; the LiveView when nil."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the control's own.")

  @spec back(map()) :: Phoenix.LiveView.Rendered.t()
  def back(assigns) do
    push_opts =
      [value: %{"screen" => assigns.screen["key"], "back" => true}]
      |> then(&if(assigns.target, do: [{:target, assigns.target} | &1], else: &1))

    assigns =
      assign(assigns,
        shown: assigns.moves["back"] == true,
        push: JS.push(assigns.event, push_opts)
      )

    ~H"""
    <button
      :if={@shown}
      type="button"
      phx-click={@push}
      class={["riddler-back" | List.wrap(@class)]}
      data-riddler-back
    >
      {@label}
    </button>
    """
  end

  defp input_id(key), do: "riddler-element-#{key}"
  defp help_id(key), do: "riddler-element-#{key}-help"
  defp held_id(key), do: "riddler-element-#{key}-held"

  defp legend_id(key), do: "riddler-element-#{key}-legend"
  defp option_id(key, value), do: "riddler-element-#{key}-option-#{value}"

  defp choice_drawn_as("dropdown", false), do: :select
  defp choice_drawn_as("list", true), do: :select
  defp choice_drawn_as(_style, _many), do: :inputs

  defp choice_name(name, true), do: name <> "[]"
  defp choice_name(name, false), do: name

  defp chosen_values(value, false) when is_binary(value), do: [value]
  defp chosen_values(values, true) when is_list(values), do: Enum.filter(values, &is_binary/1)
  defp chosen_values(_value, _many), do: []

  defp selection_bound(bound) when is_integer(bound) and bound >= 0, do: bound
  defp selection_bound(_bound), do: nil

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
