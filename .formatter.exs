# Used by "mix format"
#
# `import_deps: [:phoenix_live_view]` keeps the parens off the LiveView
# macros that export formatter locals, and the HEEx plugin formats the
# components' templates.
[
  import_deps: [:phoenix_live_view],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
