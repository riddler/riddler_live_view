### Added

- `RiddlerLiveView.Components.elements/1` draws every element of a screen through the component for its kind and a host's own kinds through a component map, `components`, that names the host's function component for each; an element of a kind nothing draws is not drawn, a notice whose text the host replaces through `unknown_text` is drawn above the elements, and every button is drawn disabled and names the notice, through the new `blocked_by` attribute of `button/1`; `unknown_kinds/2` answers those kinds so a host refuses a submit of that screen.
