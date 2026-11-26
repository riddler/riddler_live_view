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
      `heading/1`, `text/1`, `image/1`, `divider/1`, `link/1`,
      `text_question/1`, `secret_question/1`, `choice_question/1`,
      `boolean_question/1` and `button/1`.
    * `back/1` draws the Back control where the answer's `"moves"` let the
      visitor go back.
    * `elements/1` draws every element of a screen, in order, each through
      the component for its kind, a host's own kinds through the host's
      components, and an element of a kind it cannot draw not at all; the
      "Elements of a kind the package does not draw" section says what then
      happens to the screen's submit.

  The markup ships no stylesheet and no CSS framework class. Every component
  carries a `class` attribute, and a host may add its own classes through
  the `class` attribute each component takes. Every component also carries
  stable `data-riddler-*` attributes a host's stylesheet and tests can
  select on:

    * `data-riddler-element` on the markup of each element, whose value is
      the element's kind, the `"type"` the answer gives it (`"heading"`,
      `"text"`, `"image"`, `"divider"`, `"link"`, `"text_question"`,
      `"secret_question"`, `"choice_question"`, `"boolean_question"`,
      `"button"`);
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
    * `data-riddler-size` and `data-riddler-fit` on an image, whose values
      are its `"size"` and `"fit"` where it carries them, and
      `data-riddler-style` on a link, whose value is its `"style"` where it
      carries one;
    * `data-riddler-back` on the Back control;
    * `data-riddler-unknown` on the notice `elements/1` draws for a screen
      with elements it cannot draw, whose value is their kinds that are
      strings, space-separated, and
      `data-riddler-blocked` on a button that notice disables, whose value
      is the notice's `id`;
    * `data-riddler-finding` on each finding drawn, whose value is the
      finding's `"code"`, and `data-riddler-focus` on the frame's focus
      trigger, whose value is the `id` of the finding it moves focus to.

  A secret question's input never carries a value: no `value` attribute,
  whatever the element carries, and `autocomplete="off"`.

  A text's `"style"` is drawn as a class, `riddler-text-body` or
  `riddler-text-caption`, so a host's stylesheet can set a caption apart. An
  image's alt text is always drawn, as `alt=""` for a decorative image. A
  link is a plain `<a href>`: it submits no form and raises no outcome.

  ## Findings

  When riddler refuses what the visitor submitted, the host holds a list of
  `Riddler.Finding` structs, or their wire form, a map with the string keys
  `"code"`, `"message"`, `"field"`, `"element_key"`, `"position"` and
  `"author_message"`. A host passes the same list as `findings` to the frame
  and to each question component, and each draws the findings that are its
  own:

    * a question draws, beside its input, every finding whose
      `element_key` is the question's `"key"`, names each in its input's
      `aria-describedby` ahead of its help, and sets `aria-invalid="true"`
      on its input; a choice question names them from its fieldset, and
      marks and names them on each of its inputs or its `<select>`;
    * the frame draws, above the elements, every finding that names no
      question of the screen: one with no `element_key`, and one whose
      `element_key` is not the key of a question among the screen's
      `"elements"`, and names them in its `<section>`'s `aria-describedby`.

  A finding is a paragraph that can take focus, `tabindex="-1"`, and is
  never in the tab order. The text drawn is the finding's
  `"author_message"`, the text the document's author wrote for its code,
  where it is a non-blank string. Otherwise it is this package's own
  sentence for the code, which a host replaces code by code with the
  `finding_text` attribute. A finding's `"message"` is riddler's sentence for
  the host and is never drawn, so nothing a message quotes of a response
  reaches the page.

  The frame moves focus to the first finding when the findings appear: the
  first the frame draws itself, or else the first finding of the first
  question in the screen's `"elements"` that has one. It does so with a
  `phx-mounted` `Phoenix.LiveView.JS.focus/1` on a hidden trigger whose `id`
  names that finding, so focus moves whenever the first finding changes. A
  refusal that leaves the same first finding in place moves it again only
  where the host passes `refusals`, a count it changes on every refused
  submit, as `RiddlerLiveView.Journey` does: the trigger's `id` carries the
  count, so each refusal mounts a trigger of its own.

  Every `id` a component derives opens on its `id_prefix`, `"riddler"` by
  default, followed by the screen's or the question's `"key"`. A page that
  draws two screens at once, or two Journeys, passes each its own prefix, so
  no `id` is carried twice.

  ## Elements of a kind the package does not draw

  A screen may carry an element whose `"type"` is not one of the kinds
  above. A host whose screens carry kinds of its own passes `elements/1` a
  component map, `components`, that names, for each such type, the host's
  function component that draws it; that component is called with the
  element and the screen's `moves`, `findings`, `finding_text` and
  `blocked_by`. A component map may not name a kind the package draws.

  An element whose kind neither the package nor the component map draws is
  not drawn, and the visitor may not submit the screen it is on:

    * `elements/1` draws a notice above the screen's elements saying that
      part of the screen cannot be shown, in the package's own sentence or
      the text the host passes as `unknown_text`;
    * every button it draws for the screen is drawn `disabled`, names the
      notice in its `aria-describedby` and carries `data-riddler-blocked`;
    * `unknown_kinds/2` answers the kinds of the screen that nothing draws,
      so a host, or the LiveComponent that embeds these components, refuses
      a submit of that screen whatever the browser sends: a disabled button
      is the browser's to honour, not a guarantee.

  The Back control is not a submit and is not disabled.

  ## Example

  A patron registration's details screen, from the answer riddler gives:

      <RiddlerLiveView.Components.frame screen={@answer["screen"]} progress={@answer["progress"]} findings={@findings}>
        <RiddlerLiveView.Components.heading element={heading} />
        <RiddlerLiveView.Components.text element={text} />
        <RiddlerLiveView.Components.text_question element={email} findings={@findings} />
        <RiddlerLiveView.Components.button element={continue} moves={@answer["moves"]} />
        <RiddlerLiveView.Components.back screen={@answer["screen"]} moves={@answer["moves"]} />
      </RiddlerLiveView.Components.frame>
  """

  use Phoenix.Component

  # This module draws the link element kind as link/1, so it does not take
  # Phoenix.Component.link/1.
  import Phoenix.Component, except: [link: 1]

  alias Phoenix.LiveView.JS

  @question_types ~w(text_question secret_question choice_question boolean_question)

  @finding_text %{
    "response.required" => "Answer this question.",
    "response.format" => "This answer is not in the form asked for.",
    "response.out_of_range" => "This answer is outside the range allowed.",
    "response.not_an_option" => "Choose from the options given.",
    "response.invalid_shape" => "This answer could not be read."
  }

  @finding_fallback "This could not be accepted."

  @element_types ~w(heading text image divider link text_question secret_question choice_question boolean_question button)

  @unknown_fallback "Part of this screen cannot be shown here, so it cannot be sent."

  @doc """
  Draws a presented screen around its elements.

  The screen is a `<section>`. Its title, when the screen has one, is the
  section's `<h1>` and labels the section. Progress is drawn only when
  `progress` is given, as a `<progress>` whose value is the step and whose
  maximum is the number of steps; the package counts no steps itself. The
  elements render inside the frame's inner block.

  The title's `id` is derived from `id_prefix` and the screen's `"key"`, so
  a page that draws two frames of the same screen at once passes each its
  own `id_prefix`.

  Given `findings`, the frame draws, between its progress and its elements,
  each finding that names no question among the screen's `"elements"`, names
  them as the section's description, and moves focus to the first finding of
  the screen when the findings appear; the module's "Findings" section says
  which finding is first.

  The frame reads the questions from the `screen` it is given, so pass the
  answer's `"screen"` whole. A screen map without `"elements"` names no
  question, so the frame draws every finding, and a question the host draws
  inside the frame draws it again.
  """
  attr(:screen, :map,
    required: true,
    doc:
      "The answer's `\"screen\"`: its `\"key\"`, its `\"title\"`, a string or nil, and its `\"elements\"`."
  )

  attr(:findings, :list,
    default: [],
    doc:
      "The findings of a refused submit, `Riddler.Finding` structs or their wire form; the frame draws those no question of the screen draws."
  )

  attr(:finding_text, :map,
    default: %{},
    doc:
      "The text drawn, by finding code, for a finding whose author wrote no message, in place of the package's own."
  )

  attr(:id_prefix, :string,
    default: "riddler",
    doc:
      "The prefix of every `id` the component derives, `\"riddler\"` unless the host passes one; two Journeys on one page each pass their own."
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

  attr(:refusals, :integer,
    default: nil,
    doc:
      "The number of submits refused so far, where the host counts them; each new count moves focus to the first finding again."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the frame's own.")

  slot(:inner_block, required: true, doc: "The screen's elements.")

  @spec frame(map()) :: Phoenix.LiveView.Rendered.t()
  def frame(assigns) do
    %{screen: screen, findings: findings, finding_text: finding_text, id_prefix: prefix} =
      assigns

    questions = question_keys(screen["elements"])

    screen_findings =
      findings
      |> List.wrap()
      |> Enum.reject(&(finding_field(&1, :element_key) in questions))
      |> drawn_findings(screen_id(prefix, screen["key"]), finding_text)

    focus = first_finding_id(screen_findings, questions, findings, prefix)

    assigns =
      assign(assigns,
        title: present_text(screen["title"]),
        title_id: screen_id(prefix, screen["key"]) <> "-title",
        screen_findings: screen_findings,
        described_by: described_by(screen_findings, []),
        focus: focus,
        focus_id: focus && focus_trigger_id(focus, assigns.refusals)
      )

    ~H"""
    <section
      class={["riddler-screen" | List.wrap(@class)]}
      data-riddler-screen={@screen["key"]}
      aria-labelledby={@title && @title_id}
      aria-describedby={@described_by}
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
      <.finding_list findings={@screen_findings} />
      <span
        :if={@focus}
        id={@focus_id}
        hidden
        class="riddler-focus"
        data-riddler-focus={@focus}
        phx-mounted={JS.focus(to: "##{@focus}")}
      ></span>
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

  The text's `"style"` is drawn as a class beside `riddler-text`:
  `riddler-text-caption` for `"caption"`, and `riddler-text-body` for
  `"body"`, for no style and for a style riddler does not offer, since a
  text with no style is body.
  """
  attr(:element, :map,
    required: true,
    doc:
      "A `text` element of the answer: its `\"key\"` and `\"text\"` and, where present, `\"style\"`."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the paragraph's own.")

  @spec text(map()) :: Phoenix.LiveView.Rendered.t()
  def text(assigns) do
    assigns = assign(assigns, style_class: text_style_class(assigns.element["style"]))

    ~H"""
    <p
      class={["riddler-text", @style_class | List.wrap(@class)]}
      data-riddler-element="text"
      data-riddler-key={@element["key"]}
    >
      {@element["text"]}
    </p>
    """
  end

  @doc """
  Renders an `image` element as an `<img>`.

  The image's `"src"` is drawn as riddler presents it: riddler presents only
  the URLs its rule admits, and the package checks none again. Its `"alt"`
  is always drawn, so a visitor who cannot see the image is told what it
  shows; an empty `"alt"` marks the image decorative and is drawn `alt=""`,
  which tells such a visitor nothing. Its `"size"` and `"fit"`, hints a
  renderer owns, are carried as `data-riddler-size` and `data-riddler-fit`
  where they are strings, and are drawn no differently.

  An image with no `"src"` renders nothing; riddler presents none.
  """
  attr(:element, :map,
    required: true,
    doc:
      "An `image` element of the answer: its `\"key\"`, `\"src\"` and `\"alt\"` and, where present, `\"size\"` and `\"fit\"`."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the image's own.")

  @spec image(map()) :: Phoenix.LiveView.Rendered.t()
  def image(assigns) do
    element = assigns.element

    assigns =
      assign(assigns,
        src: present_text(element["src"]),
        alt: if(is_binary(element["alt"]), do: element["alt"], else: ""),
        size: present_text(element["size"]),
        fit: present_text(element["fit"])
      )

    ~H"""
    <img
      :if={@src}
      src={@src}
      alt={@alt}
      class={["riddler-image" | List.wrap(@class)]}
      data-riddler-element="image"
      data-riddler-key={@element["key"]}
      data-riddler-size={@size}
      data-riddler-fit={@fit}
    />
    """
  end

  @doc """
  Renders a `divider` element as an `<hr>`, a rule between the elements
  before and after it.
  """
  attr(:element, :map,
    required: true,
    doc: "A `divider` element of the answer: its `\"key\"`."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the rule's own.")

  @spec divider(map()) :: Phoenix.LiveView.Rendered.t()
  def divider(assigns) do
    ~H"""
    <hr
      class={["riddler-divider" | List.wrap(@class)]}
      data-riddler-element="divider"
      data-riddler-key={@element["key"]}
    />
    """
  end

  @doc """
  Renders a `link` element as an `<a href>` whose text is its `"label"`.

  A link is a plain navigation: it submits no form, carries no outcome and
  pushes no event, and riddler never lists it among the `"outcomes"` of the
  moves. Following it is the browser's navigation, of which the host hears
  nothing. The `"href"` is drawn as riddler presents it: riddler presents
  only the URLs its rule admits, and the package checks none again. The
  link's `"style"`, a hint a renderer owns, is carried as
  `data-riddler-style` where it is a string, and drawn no differently.

  A link whose label is blank, or that has no `"href"`, renders nothing: a
  link with no text is read out as a bare link.
  """
  attr(:element, :map,
    required: true,
    doc:
      "A `link` element of the answer: its `\"key\"`, `\"label\"` and `\"href\"` and, where present, `\"style\"`."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the link's own.")

  @spec link(map()) :: Phoenix.LiveView.Rendered.t()
  def link(assigns) do
    element = assigns.element

    assigns =
      assign(assigns,
        href: present_text(element["href"]),
        label: present_text(element["label"]),
        style: present_text(element["style"])
      )

    ~H"""
    <a
      :if={@href && @label}
      href={@href}
      class={["riddler-link" | List.wrap(@class)]}
      data-riddler-element="link"
      data-riddler-key={@element["key"]}
      data-riddler-style={@style}
    >
      {@label}
    </a>
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
  carries no `pattern`, `min` or `max`, so the browser is not asked to check
  the format: riddler does. The browser's own checks for the input's `type`
  and for `required` still run, and can stop a submit with the browser's own
  message; a host that wants none of them draws the form itself and adds
  `novalidate` to it.

  Given `findings`, the question draws those whose `element_key` is its
  `"key"` after the input, names them in the input's description ahead of
  the help, and marks the input `aria-invalid="true"`; the module's
  "Findings" section says what text each shows.

  The input's `id` is derived from `id_prefix` and the question's `"key"`,
  and its `name` is the key unless the host passes one.
  """
  attr(:element, :map,
    required: true,
    doc:
      "A `text_question` element of the answer: its `\"key\"`, `\"label\"` and, where present, `\"help\"`, `\"placeholder\"`, `\"required\"`, `\"format\"` and `\"value\"`."
  )

  attr(:name, :string, default: nil, doc: "The input's `name`; the element's `\"key\"` when nil.")

  attr(:class, :any, default: nil, doc: "Classes added to the question's own.")

  attr(:findings, :list,
    default: [],
    doc:
      "The findings of a refused submit, `Riddler.Finding` structs or their wire form; the question draws those whose `element_key` is its `\"key\"`."
  )

  attr(:finding_text, :map,
    default: %{},
    doc:
      "The text drawn, by finding code, for a finding whose author wrote no message, in place of the package's own."
  )

  attr(:id_prefix, :string,
    default: "riddler",
    doc:
      "The prefix of every `id` the component derives, `\"riddler\"` unless the host passes one; two Journeys on one page each pass their own."
  )

  @spec text_question(map()) :: Phoenix.LiveView.Rendered.t()
  def text_question(assigns) do
    key = assigns.element["key"]
    prefix = assigns.id_prefix
    help = present_text(assigns.element["help"])
    findings = element_findings(assigns, key)

    assigns =
      assign(assigns,
        input_id: input_id(prefix, key),
        input_name: assigns.name || key,
        input_type: input_type(assigns.element["format"]),
        value: present_value(assigns.element["value"]),
        help: help,
        help_id: help_id(prefix, key),
        drawn_findings: findings,
        invalid: invalid(findings),
        described_by: described_by(findings, [help && help_id(prefix, key)])
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
        aria-invalid={@invalid}
        aria-describedby={@described_by}
        class="riddler-input"
        data-riddler-input
      />
      <.finding_list findings={@drawn_findings} />
      <p :if={@help} id={@help_id} class="riddler-help" data-riddler-help>{@help}</p>
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

  Given `findings`, the question draws those whose `element_key` is its
  `"key"` after the input, names them in the input's description ahead of
  what is held and the help, and marks the input `aria-invalid="true"`. No
  finding carries the response, and a finding's `"message"` is not drawn.

  The input's `id` is derived from `id_prefix` and the question's `"key"`.
  Its `name` is `riddler-password[` and the key and `]` unless the host
  passes one, so the submitted params carry the value under
  `"riddler-password"`, keyed by the question's key. LiveView logs the
  params of every event at the `:debug` level after Phoenix's
  `:filter_parameters`, whose default filters each parameter whose name
  contains `password`; the name keeps the value out of that log line
  wherever the host keeps that default. A host that passes its own `name`
  keeps the value out of the log itself.
  """
  attr(:element, :map,
    required: true,
    doc:
      "A `secret_question` element of the answer: its `\"key\"`, `\"label\"` and `\"held\"` and, where present, `\"help\"` and `\"required\"`."
  )

  attr(:name, :string,
    default: nil,
    doc: "The input's `name`; `riddler-password[` and the element's `\"key\"` and `]` when nil."
  )

  attr(:held_text, :string,
    default: "A value is held.",
    doc: "The text shown where a value is held."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the question's own.")

  attr(:findings, :list,
    default: [],
    doc:
      "The findings of a refused submit, `Riddler.Finding` structs or their wire form; the question draws those whose `element_key` is its `\"key\"`."
  )

  attr(:finding_text, :map,
    default: %{},
    doc:
      "The text drawn, by finding code, for a finding whose author wrote no message, in place of the package's own."
  )

  attr(:id_prefix, :string,
    default: "riddler",
    doc:
      "The prefix of every `id` the component derives, `\"riddler\"` unless the host passes one; two Journeys on one page each pass their own."
  )

  @spec secret_question(map()) :: Phoenix.LiveView.Rendered.t()
  def secret_question(assigns) do
    key = assigns.element["key"]
    prefix = assigns.id_prefix
    held = assigns.element["held"] == true
    help = present_text(assigns.element["help"])
    findings = element_findings(assigns, key)

    assigns =
      assign(assigns,
        input_id: input_id(prefix, key),
        input_name: assigns.name || "riddler-password[#{key}]",
        held: held,
        held_id: held_id(prefix, key),
        help: help,
        help_id: help_id(prefix, key),
        required: assigns.element["required"] == true and not held,
        drawn_findings: findings,
        invalid: invalid(findings),
        described_by:
          described_by(findings, [held && held_id(prefix, key), help && help_id(prefix, key)])
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
        aria-invalid={@invalid}
        aria-describedby={@described_by}
        class="riddler-input"
        data-riddler-input
      />
      <.finding_list findings={@drawn_findings} />
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
  names as its description. Each option input's `id` is derived from
  `id_prefix`, the question's `"key"` and the option's `"value"`, a
  `<select>`'s from the prefix and the key alone, and the `name` is the
  key unless the host passes one; under `"many"` the name ends in `[]`, so
  the submitted params carry a list.

  Given `findings`, the question draws those whose `element_key` is its
  `"key"` after its options, names them in the fieldset's description ahead
  of the help, and marks each option input, or the `<select>`,
  `aria-invalid="true"` and names them in its description too.
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

  attr(:findings, :list,
    default: [],
    doc:
      "The findings of a refused submit, `Riddler.Finding` structs or their wire form; the question draws those whose `element_key` is its `\"key\"`."
  )

  attr(:finding_text, :map,
    default: %{},
    doc:
      "The text drawn, by finding code, for a finding whose author wrote no message, in place of the package's own."
  )

  attr(:id_prefix, :string,
    default: "riddler",
    doc:
      "The prefix of every `id` the component derives, `\"riddler\"` unless the host passes one; two Journeys on one page each pass their own."
  )

  @spec choice_question(map()) :: Phoenix.LiveView.Rendered.t()
  def choice_question(assigns) do
    element = assigns.element
    key = element["key"]
    prefix = assigns.id_prefix
    many = element["select"] == "many"
    help = present_text(element["help"])
    chosen = chosen_values(element["value"], many)
    findings = element_findings(assigns, key)

    options =
      for option <- List.wrap(element["answer_options"]) do
        %{
          value: option["value"],
          label: option["label"],
          id: option_id(prefix, key, option["value"]),
          chosen: option["value"] in chosen
        }
      end

    assigns =
      assign(assigns,
        options: options,
        many: many,
        drawn_as: choice_drawn_as(element["style"], many),
        legend_id: legend_id(prefix, key),
        select_id: input_id(prefix, key),
        input_name: choice_name(assigns.name || key, many),
        required: not many and element["required"] == true,
        min_selections: many && selection_bound(element["min_selections"]),
        max_selections: many && selection_bound(element["max_selections"]),
        help: help,
        help_id: help_id(prefix, key),
        drawn_findings: findings,
        invalid: invalid(findings),
        finding_ids: described_by(findings, []),
        described_by: described_by(findings, [help && help_id(prefix, key)])
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
          aria-invalid={@invalid}
          aria-describedby={@finding_ids}
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
        aria-invalid={@invalid}
        aria-describedby={@finding_ids}
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
      <.finding_list findings={@drawn_findings} />
      <p :if={@help} id={@help_id} class="riddler-help" data-riddler-help>{@help}</p>
    </fieldset>
    """
  end

  @doc """
  Renders a `boolean_question` element as a lone labelled checkbox.

  The question's `"label"` is the checkbox's `<label>`, and the checkbox
  submits `"true"` when it is ticked; an unticked checkbox submits nothing.
  It is drawn ticked where the answer presents `true` for the question.
  riddler validates a boolean question's response as `true` or `false`, so
  the code that hands the submit to riddler turns the submitted `"true"`
  into `true` and an absent one into `false` first, as
  `RiddlerLiveView.Journey` does.

  The checkbox carries `required` where the question is required: riddler
  reads a required boolean question as one whose response must be `true`,
  which is what `required` asks of a checkbox. The question's `"help"`, when
  it has one, is a paragraph the checkbox names as its description.

  Given `findings`, the question draws those whose `element_key` is its
  `"key"` after the label, names them in the checkbox's description ahead
  of the help, and marks the checkbox `aria-invalid="true"`.

  The checkbox's `id` is derived from `id_prefix` and the question's
  `"key"`, and its `name` is the key unless the host passes one.
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

  attr(:findings, :list,
    default: [],
    doc:
      "The findings of a refused submit, `Riddler.Finding` structs or their wire form; the question draws those whose `element_key` is its `\"key\"`."
  )

  attr(:finding_text, :map,
    default: %{},
    doc:
      "The text drawn, by finding code, for a finding whose author wrote no message, in place of the package's own."
  )

  attr(:id_prefix, :string,
    default: "riddler",
    doc:
      "The prefix of every `id` the component derives, `\"riddler\"` unless the host passes one; two Journeys on one page each pass their own."
  )

  @spec boolean_question(map()) :: Phoenix.LiveView.Rendered.t()
  def boolean_question(assigns) do
    key = assigns.element["key"]
    prefix = assigns.id_prefix
    help = present_text(assigns.element["help"])
    findings = element_findings(assigns, key)

    assigns =
      assign(assigns,
        input_id: input_id(prefix, key),
        input_name: assigns.name || key,
        checked: assigns.element["value"] == true,
        required: assigns.element["required"] == true,
        help: help,
        help_id: help_id(prefix, key),
        drawn_findings: findings,
        invalid: invalid(findings),
        described_by: described_by(findings, [help && help_id(prefix, key)])
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
        aria-invalid={@invalid}
        aria-describedby={@described_by}
        class="riddler-input"
        data-riddler-input
      />
      <label for={@input_id} class="riddler-label" data-riddler-label>{@element["label"]}</label>
      <.finding_list findings={@drawn_findings} />
      <p :if={@help} id={@help_id} class="riddler-help" data-riddler-help>{@help}</p>
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
  stop the press, and `data-riddler-validates="false"`. Every other button
  carries `data-riddler-validates="true"`, riddler's default. The attribute
  is a hook for a host's stylesheet, tests and client scripts, not the
  server's source: a form submit carries only the pressed button's `name`
  and `value`. The submit names the outcome, not the button's key: in a
  document riddler validates, no two buttons a screen shows together raise
  one outcome, so the host finds the pressed button, and whether it
  validates, by its outcome. The button's `"style"`, a string from the open
  set riddler leaves to a renderer, is carried as `data-riddler-style` and
  drawn no differently.

  The submitted outcome comes from the page and a visitor can change it, so
  the host checks it is among the `"outcomes"` of the moves it presented
  before it acts on it, as `Riddler.Journey.decode_submit/1` says.

  Given `blocked_by`, the `id` of the notice `elements/1` draws for a screen
  it cannot draw in full, the button is drawn `disabled`, names the notice
  in its `aria-describedby` and carries `data-riddler-blocked`.
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

  attr(:blocked_by, :string,
    default: nil,
    doc:
      "The `id` of a notice saying why the screen cannot be submitted; given one, the button is drawn disabled and names it."
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
      disabled={@blocked_by != nil}
      aria-describedby={@blocked_by}
      data-riddler-blocked={@blocked_by}
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
  The back request comes from the page and a visitor can send one the moves
  did not offer, so the host checks that the moves it presented say
  `"back"` is `true` before it acts on it, as
  `Riddler.Journey.decode_submit/1` says.
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

  @doc """
  Draws every element of a screen, in the screen's order.

  Each element of the screen's `"elements"` is drawn by the component for
  its `"type"`: one of this module's for a kind the package draws, or the
  host's own for a type the component map, `components`, names. A host's
  component is called with exactly the assigns `element`, `moves`,
  `findings`, `finding_text` and `blocked_by`, and draws the element as it
  chooses; it is called as a function, so the defaults of any `attr` it
  declares are not applied.
  `findings` and `finding_text` pass to every question.

  An element of any other kind is not drawn. Where the screen has one, a
  notice is drawn above the elements, a status region (a paragraph with
  `role="status"`) whose text is `unknown_text`, and every button is drawn
  disabled and names the notice; `unknown_kinds/2` answers the same kinds for
  the host's submit. The module's "Elements of a kind the package does not draw" section says why.

  The notice's `id` is derived from `id_prefix` and the screen's `"key"`,
  and `id_prefix` passes to every question.

  Raises `ArgumentError` for a component map that names a kind the package
  draws, or whose value for a type is not a function of one argument: both
  are a host's wiring, never a visitor's input.
  """
  attr(:screen, :map,
    required: true,
    doc: "The answer's `\"screen\"`: its `\"key\"` and its `\"elements\"`."
  )

  attr(:moves, :map,
    required: true,
    doc: "The answer's `\"moves\"`: which buttons are drawn."
  )

  attr(:components, :map,
    default: %{},
    doc:
      "The component map: for each of the host's own element types, the host's function component that draws it."
  )

  attr(:findings, :list,
    default: [],
    doc:
      "The findings of a refused submit, `Riddler.Finding` structs or their wire form, passed to every question."
  )

  attr(:finding_text, :map,
    default: %{},
    doc:
      "The text drawn, by finding code, for a finding whose author wrote no message, passed to every question."
  )

  attr(:id_prefix, :string,
    default: "riddler",
    doc:
      "The prefix of every `id` the component derives, `\"riddler\"` unless the host passes one; two Journeys on one page each pass their own."
  )

  attr(:unknown_text, :string,
    default: @unknown_fallback,
    doc: "The notice's text, drawn where the screen has an element nothing draws."
  )

  attr(:class, :any, default: nil, doc: "Classes added to the notice's own.")

  @spec elements(map()) :: Phoenix.LiveView.Rendered.t()
  def elements(assigns) do
    %{screen: screen, components: components} = assigns
    unknown = unknown_kinds(screen, components)

    assigns =
      assign(assigns,
        items: List.wrap(screen["elements"]),
        unknown: unknown |> Enum.filter(&is_binary/1) |> Enum.join(" "),
        notice_id:
          if(unknown != [], do: screen_id(assigns.id_prefix, screen["key"]) <> "-unknown"),
        notice: present_text(assigns.unknown_text) || @unknown_fallback
      )

    ~H"""
    <p
      :if={@notice_id}
      id={@notice_id}
      role="status"
      class={["riddler-unknown" | List.wrap(@class)]}
      data-riddler-unknown={@unknown}
    >
      {@notice}
    </p>
    <.element
      :for={element <- @items}
      element={element}
      components={@components}
      moves={@moves}
      findings={@findings}
      finding_text={@finding_text}
      blocked_by={@notice_id}
      id_prefix={@id_prefix}
    />
    """
  end

  @doc """
  Answers the kinds of a screen's elements that neither the package nor the
  component map draws, each once, in the order the screen first carries
  them; `[]` where every element is drawn.

  A screen with an element of such a kind is not to be submitted: the
  module's "Elements of a kind the package does not draw" section says why.
  An element whose `"type"` is not a string is of no kind anything draws;
  it is answered as `nil`.

  Raises `ArgumentError` for a component map `elements/1` refuses.
  """
  @spec unknown_kinds(map(), %{optional(String.t()) => (map() -> term())}) :: [String.t() | nil]
  def unknown_kinds(screen, components \\ %{}) do
    check_components!(components)

    screen
    |> Map.get("elements")
    |> List.wrap()
    |> Enum.filter(&(drawer(&1, components) == :none))
    |> Enum.map(&element_kind/1)
    |> Enum.uniq()
  end

  # One element, drawn by the component for its kind; nothing for a kind
  # nothing draws.
  attr(:element, :map, required: true)
  attr(:components, :map, required: true)
  attr(:moves, :map, required: true)
  attr(:findings, :list, required: true)
  attr(:finding_text, :map, required: true)
  attr(:blocked_by, :string, required: true)
  attr(:id_prefix, :string, required: true)

  defp element(assigns) do
    assigns = assign(assigns, drawer: drawer(assigns.element, assigns.components))

    ~H"""
    <.heading :if={@drawer == "heading"} element={@element} />
    <.text :if={@drawer == "text"} element={@element} />
    <.image :if={@drawer == "image"} element={@element} />
    <.divider :if={@drawer == "divider"} element={@element} />
    <.link :if={@drawer == "link"} element={@element} />
    <.text_question
      :if={@drawer == "text_question"}
      element={@element}
      findings={@findings}
      finding_text={@finding_text}
      id_prefix={@id_prefix}
    />
    <.secret_question
      :if={@drawer == "secret_question"}
      element={@element}
      findings={@findings}
      finding_text={@finding_text}
      id_prefix={@id_prefix}
    />
    <.choice_question
      :if={@drawer == "choice_question"}
      element={@element}
      findings={@findings}
      finding_text={@finding_text}
      id_prefix={@id_prefix}
    />
    <.boolean_question
      :if={@drawer == "boolean_question"}
      element={@element}
      findings={@findings}
      finding_text={@finding_text}
      id_prefix={@id_prefix}
    />
    <.button :if={@drawer == "button"} element={@element} moves={@moves} blocked_by={@blocked_by} />
    {if is_function(@drawer), do: host_component(@drawer, assigns)}
    """
  end

  defp host_component(fun, assigns) do
    fun.(%{
      __changed__: nil,
      element: assigns.element,
      moves: assigns.moves,
      findings: assigns.findings,
      finding_text: assigns.finding_text,
      blocked_by: assigns.blocked_by
    })
  end

  # What draws an element: the kind's own name for a kind the package draws,
  # the host's function for a kind the component map names, :none otherwise.
  defp drawer(element, components) do
    kind = element_kind(element)

    cond do
      kind in @element_types -> kind
      is_binary(kind) and is_map_key(components, kind) -> Map.fetch!(components, kind)
      true -> :none
    end
  end

  defp element_kind(%{"type" => type}) when is_binary(type), do: type
  defp element_kind(_element), do: nil

  defp check_components!(components) when is_map(components) do
    Enum.each(components, fn
      {type, _fun} when type in @element_types ->
        raise ArgumentError,
              "the component map names #{inspect(type)}, a kind this package draws"

      {type, fun} when is_binary(type) and is_function(fun, 1) ->
        :ok

      entry ->
        raise ArgumentError,
              "a component map entry is an element type and a function component of one argument, got: #{inspect(entry)}"
    end)
  end

  defp check_components!(components) do
    raise ArgumentError, "the component map is a map, got: #{inspect(components)}"
  end

  # The findings a component draws, each as one focusable paragraph.
  attr(:findings, :list, required: true)

  defp finding_list(assigns) do
    ~H"""
    <p
      :for={finding <- @findings}
      id={finding.id}
      tabindex="-1"
      class="riddler-finding"
      data-riddler-finding={finding.code}
    >
      {finding.text}
    </p>
    """
  end

  defp element_findings(
         %{findings: findings, finding_text: finding_text, id_prefix: prefix},
         key
       )
       when is_binary(key) do
    findings
    |> List.wrap()
    |> Enum.filter(&(finding_field(&1, :element_key) == key))
    |> drawn_findings(element_id(prefix, key), finding_text)
  end

  defp element_findings(_assigns, _key), do: []

  defp drawn_findings(findings, id_prefix, finding_text) do
    findings
    |> Enum.with_index(1)
    |> Enum.map(fn {finding, index} ->
      code = finding_field(finding, :code)

      %{
        id: "#{id_prefix}-finding-#{index}",
        code: code,
        text:
          present_text(finding_field(finding, :author_message)) || own_text(code, finding_text)
      }
    end)
  end

  # The package's own sentence for a code, or the host's in its place. A
  # finding's message is riddler's sentence for the host and is not drawn.
  defp own_text(code, finding_text) do
    with nil <- present_text(Map.get(finding_text || %{}, code)) do
      Map.get(@finding_text, code, @finding_fallback)
    end
  end

  # A finding is a `Riddler.Finding` struct or its wire form, string-keyed.
  defp finding_field(finding, field) when is_map(finding) do
    case Map.fetch(finding, field) do
      {:ok, value} -> value
      :error -> Map.get(finding, Atom.to_string(field))
    end
  end

  defp finding_field(_finding, _field), do: nil

  defp question_keys(elements) do
    for %{"type" => type, "key" => key} <- List.wrap(elements),
        type in @question_types and is_binary(key),
        do: key
  end

  # The first finding of the screen: the frame's own first, else the first
  # finding of the first question, in the screen's order, that has one.
  defp first_finding_id([%{id: id} | _], _questions, _findings, _prefix), do: id

  defp first_finding_id([], questions, findings, prefix) do
    keys = findings |> List.wrap() |> Enum.map(&finding_field(&1, :element_key))

    Enum.find_value(questions, fn key ->
      if key in keys, do: element_id(prefix, key) <> "-finding-1"
    end)
  end

  # The focus trigger's id names the finding it moves focus to and, where
  # the host counts refused submits, the count, so each refusal mounts a
  # trigger of its own and focus moves again.
  defp focus_trigger_id(focus, nil), do: "#{focus}-focus"
  defp focus_trigger_id(focus, refusals), do: "#{focus}-focus-#{refusals}"

  defp invalid([]), do: nil
  defp invalid(_findings), do: "true"

  defp described_by(findings, others) do
    case Enum.map(findings, & &1.id) ++ Enum.filter(others, & &1) do
      [] -> nil
      ids -> Enum.join(ids, " ")
    end
  end

  defp element_id(prefix, key), do: "#{prefix}-element-#{key}"
  defp screen_id(prefix, key), do: "#{prefix}-screen-#{key}"

  defp input_id(prefix, key), do: element_id(prefix, key)
  defp help_id(prefix, key), do: element_id(prefix, key) <> "-help"
  defp held_id(prefix, key), do: element_id(prefix, key) <> "-held"

  defp legend_id(prefix, key), do: element_id(prefix, key) <> "-legend"
  defp option_id(prefix, key, value), do: element_id(prefix, key) <> "-option-#{value}"

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

  defp text_style_class("caption"), do: "riddler-text-caption"
  defp text_style_class(_style), do: "riddler-text-body"

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
