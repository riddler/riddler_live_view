### Added

- Every component draws an element's `accessible_label` as the `aria-label` of the node a visitor reaches, and its `accessible_description` as hidden text that node names last in its `aria-describedby`; a text, whose paragraph takes no name, draws only the description, and an element that carries neither draws the markup it drew before.
- `RiddlerLiveView.Components.heading/1`, `text/1`, `image/1`, `divider/1`, `link/1` and `button/1` take an `id_prefix`, which `elements/1` passes them, for the `id` of the description they draw.
- `RiddlerLiveView.Components.choice_question/1` names its help in the `aria-describedby` of a `<select>` or a search input as well as of its fieldset.
