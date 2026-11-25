### Added

- `RiddlerLiveView.Components.button/1` renders a `button` element as a submit button whose name and value carry its outcome, drawn only where the answer's moves list that outcome; a button that does not validate carries `formnovalidate` and `data-riddler-validates="false"`. `back/1` draws the Back control only where the moves say back, and pushes riddler's back request, the screen's key and `back` true with no outcome.
