# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Entries for unreleased work are not written here directly. Each issue drops a
fragment in [`changelog.d/`](https://github.com/riddler/riddler_live_view/blob/main/changelog.d/README.md); the fragments are assembled
into a version section at release. See that README for the format and for when a
change warrants an entry at all.

## [0.2.0] 2026-11-27

This release adds an optional re-present hook to `RiddlerLiveView.Journey`.
A host that passes a `re_present` function has the presented screen drawn
again against what the visitor has typed but not sent, so a button a
same-screen condition reveals can be pressed. A host that does not pass it
sees no change from 0.1.0: the form carries no change event. A host that
passes it must check a submitted outcome against the moves resolved with the
submitted responses, not with the context alone, so that a button the draft
revealed is accepted only where the submitted responses reveal it too. It
still requires riddler `~> 0.9` and phoenix_live_view `~> 1.2`.

### Added

- `RiddlerLiveView.Journey` takes an optional `re_present` function: with it, the form sends a change event and the screen is drawn again from the host's answer for what the visitor has typed, so a button a same-screen condition reveals can be pressed; without it nothing changes.

## [0.1.0] 2026-11-26

The first release of `riddler_live_view`, the Phoenix LiveView face of
riddler. It renders what riddler presents for one step of a Journey as plain
semantic HTML, a function component for each element kind and the
`RiddlerLiveView.Journey` LiveComponent a host embeds, and it owns no state
and steps nothing: the host's engine steps the Journey, and the host decides
who may see it. It requires riddler `~> 0.9` and phoenix_live_view `~> 1.2`.

### Added

- `RiddlerLiveView.Components` renders a presented screen as plain semantic HTML: `frame/1` draws the screen with its title, and progress where the host supplied it, around its elements, and `heading/1` and `text/1` render the `heading` and `text` elements, each with a `class` and stable `data-riddler-*` attributes and no stylesheet.
- `RiddlerLiveView.Journey` asks `Riddler.Journey.Access.check/4` of the host's `access` module on mount, on every refresh, before every submit and before every back, and again when the `journey`, `host`, `access` or `actor` assign changes, and draws one refusal, carrying `data-riddler-refused` and the new `refused_text`, alike for a Journey the host does not have and one the actor may not see; a membership revoked after the mount refuses the next submit or back.
- `RiddlerLiveView.Journey` raises `ArgumentError` when it mounts without an `access` module, or with one that is not a loaded module exporting `member?/2`.
- A host callback or access module that raises, throws or exits, a host answer outside `Riddler.Journey.Host`, an answer not of a shape `Riddler.Journey.present/3` gives (a waiting answer's `retry_after_ms` that is not an integer of 0 or more among them), and an answer or findings whose markup raises when rendered no longer crash the LiveView: the component draws the refusal on present and on the access check, keeps what is drawn on submit and back, and logs one line naming the callback and the kind of failure, never the event's parameters.
- `RiddlerLiveView.Journey` waits at most 4294967295 milliseconds, about 49.7 days, before asking the host again after a waiting answer: a longer `retry_after_ms` waits that long.
- `RiddlerLiveView.Journey`, the LiveComponent a host's LiveView embeds: given the host's name for a Journey and its `Riddler.Journey.Host` module, it draws the screen the host presents, hands the host each submit and back request built from the presented answer, draws the host's findings beside the questions they name, draws waiting and asks the host again after the answer's `retry_after_ms`, and draws done; an outcome the moves did not list, a back request the moves did not offer, a form from another screen and a screen with an element nothing draws are refused without calling the host.
- Every component that derives an `id` takes `id_prefix`, so two screens or two Journeys on one page carry no `id` twice.
- `RiddlerLiveView.Components.frame/1` takes `refusals`, a count of refused submits, so focus moves to the first finding again on every refusal.
- `RiddlerLiveView.Components.secret_question/1` names its input `riddler-password[` and the question's key and `]` unless the host passes a `name`, so Phoenix's default `:filter_parameters` keeps the value out of the line LiveView logs for each event.
- `RiddlerLiveView.Components.image/1`, `divider/1` and `link/1` render the `image`, `divider` and `link` elements: an image is an `img` whose `alt` is always drawn, `alt=""` for a decorative image, with its size and fit carried as `data-riddler-size` and `data-riddler-fit`; a divider is an `hr`; a link is a plain `a href` that submits no form and raises no outcome, with its style carried as `data-riddler-style`. `elements/1` draws all three, so a screen carrying them is no longer blocked as one with a kind the package does not draw.
- `RiddlerLiveView.Components.text/1` draws a text's style as a class, `riddler-text-caption` for a caption and `riddler-text-body` otherwise.
- Every component draws an element's `accessible_label` as the `aria-label` of the node a visitor reaches, and its `accessible_description` as hidden text that node names last in its `aria-describedby`; a text, whose paragraph takes no name, draws only the description, and an element that carries neither draws the markup it drew before.
- `RiddlerLiveView.Components.heading/1`, `text/1`, `image/1`, `divider/1`, `link/1` and `button/1` take an `id_prefix`, which `elements/1` passes them, for the `id` of the description they draw.
- `RiddlerLiveView.Components.choice_question/1` names its help in the `aria-describedby` of a `<select>` or a search input as well as of its fieldset.
- `RiddlerLiveView.Components.text_question/1` draws a question of the `date` or `time` format as the browser's own date or time input, carrying its presented `min` and `max`, and submits a value in riddler's shape for the format; a time input carries `step="1"` where its presented value or a bound carries seconds; a question of the `datetime` format stays a plain text input.
- `RiddlerLiveView.Components.text_question/1` draws the `multiline` hint as a `textarea` under no format or the `pattern` format, and under the `integer` or `number` format the `slider` hint as a range input, only where its `min` and `max` are both numbers, and the `stepper` hint as a number input, each carrying its bounds and `step`, and under `integer` only where every numeric bound is a whole number; it draws a hint it does not draw for the question as the question with no hint; the hint is carried as `data-riddler-style`.
- `RiddlerLiveView.Components.choice_question/1` draws the `chips` hint as the question's radio buttons or checkboxes, each marked `riddler-chip`, and a `searchable` question under `select` one as a text input bound to a `datalist` of the options, carrying `data-riddler-style` and `data-riddler-searchable`.
- `RiddlerLiveView.Components.choice_question/1` draws an option's `description` with an `id` derived from the option's and names it in that option's `aria-describedby`: after the option's label beside a radio button or a checkbox, and in a description list after a `select` or a `datalist`.
- `RiddlerLiveView.Components.button/1` renders a `button` element as a submit button whose name and value carry its outcome, drawn only where the answer's moves list that outcome; a button that does not validate carries `formnovalidate` and `data-riddler-validates="false"`. `back/1` draws the Back control only where the moves say back, and pushes riddler's back request, the screen's key and `back` true with no outcome.
- `RiddlerLiveView.Components.text_question/1` and `secret_question/1` render the `text_question` and `secret_question` elements as a labelled input with its help: the text question's input takes its type from the format and draws the presented value, and the secret question's password input sets `autocomplete="off"`, never carries a value and says when a value is held.
- The question components and `RiddlerLiveView.Components.frame/1` take a refused submit's `findings`, as `Riddler.Finding` structs or their wire form: a question draws each finding whose `element_key` is its key beside its input, names it in the input's `aria-describedby` ahead of the help and sets `aria-invalid="true"`, the frame draws the findings that name no question of the screen, and focus moves to the first finding when they appear; a finding shows its `author_message` where the author wrote one and otherwise the package's own text for its code, which a host replaces through `finding_text`, and never its `message`.
- `RiddlerLiveView.Journey` takes a `time_zone` assign, the visitor's time zone as a name the host's time zone database resolves; with it a question of the `datetime` format is drawn as a datetime-local input, its presented `min`, `max` and value drawn as wall times in that zone, and the zone's offset is added to the submitted wall time so riddler validates an instant. `RiddlerLiveView.Components.text_question/1` and `elements/1` take the same `time_zone` attribute. Without one a datetime question stays a plain text input.
- `RiddlerLiveView.Components.choice_question/1` and `boolean_question/1` render the `choice_question` and `boolean_question` elements: a choice question is a fieldset whose legend is its label, drawing radio buttons or a dropdown under `select` one and checkboxes or a multiple select under many, with the presented selection chosen and its selection bounds carried as data attributes, and a boolean question is a lone labelled checkbox, ticked where the answer presents true.
- `RiddlerLiveView.Components.elements/1` draws every element of a screen through the component for its kind and a host's own kinds through a component map, `components`, that names the host's function component for each; an element of a kind nothing draws is not drawn, a notice whose text the host replaces through `unknown_text` is drawn above the elements, and every button is drawn disabled and names the notice, through the new `blocked_by` attribute of `button/1`; `unknown_kinds/2` answers those kinds so a host refuses a submit of that screen.

### Changed

- The package requires riddler `~> 0.9`, the first release that presents the image, divider and link elements and a text's style.
