# Used by "mix format"
#
# `import_deps: [:phoenix_live_view]` keeps the parens off the LiveView
# macros that export formatter locals. There is no HEEx in lib/ yet, so the
# HEEx plugin joins when the first component lands.
[
  import_deps: [:phoenix_live_view],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
