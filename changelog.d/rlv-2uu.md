### Added

- `RiddlerLiveView.Components.image/1`, `divider/1` and `link/1` render the `image`, `divider` and `link` elements: an image is an `img` whose `alt` is always drawn, `alt=""` for a decorative image, with its size and fit carried as `data-riddler-size` and `data-riddler-fit`; a divider is an `hr`; a link is a plain `a href` that submits no form and raises no outcome, with its style carried as `data-riddler-style`. `elements/1` draws all three, so a screen carrying them is no longer blocked as one with a kind the package does not draw.
- `RiddlerLiveView.Components.text/1` draws a text's style as a class, `riddler-text-caption` for a caption and `riddler-text-body` otherwise.

### Changed

- The package requires riddler `~> 0.9`, the first release that presents the image, divider and link elements and a text's style.
