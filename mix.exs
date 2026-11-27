defmodule RiddlerLiveView.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/riddler/riddler_live_view"

  def project do
    [
      app: :riddler_live_view,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "RiddlerLiveView",
      description:
        "Phoenix LiveView components that render what Riddler presents for a Journey step: function components per element kind and a LiveComponent a host embeds",
      source_url: @source_url,
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_apps: [:ex_unit, :mix]],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      name: "RiddlerLiveView",
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/riddler_live_view",
      source_url: @source_url,
      main: "readme",
      # The README is the front page and the CHANGELOG sits beside it, both
      # ungrouped at the top of the sidebar. Every guide is grouped under
      # "How-to guides". A group is added with its first page, never empty.
      # The decision records under docs/adr are a record for contributors,
      # not pages for a reader of the package: they are not extras.
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/guides/render-a-journey.md",
        "docs/guides/scope-a-path.md",
        "docs/guides/draw-an-element-of-your-own-kind.md",
        "docs/guides/offer-an-authored-skip.md"
      ],
      groups_for_extras: [
        "How-to guides": ~r{docs/guides/}
      ],
      # The root module matches none of these on purpose: it is the package's
      # own overview and belongs above the two seams.
      groups_for_modules: [
        Components: [RiddlerLiveView.Components],
        Journey: [RiddlerLiveView.Journey]
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp package do
    [
      name: "riddler_live_view",
      licenses: ["MIT"],
      files: ~w(lib mix.exs .formatter.exs README.md LICENSE CHANGELOG.md),
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  # Two runtime dependencies and no more. `riddler` presents what a visitor
  # sees at one step of a Journey and `phoenix_live_view` renders it. Nothing
  # in the statifier family is a dependency here and nothing here may become
  # one: a host wires its execution engine to this package, not the reverse.
  # The floor on `riddler` is 0.9, the first release whose presented screen
  # carries the `image`, `divider` and `link` elements and a text's `style`,
  # each of which a component here draws.
  defp deps do
    [
      # Runtime
      {:riddler, "~> 0.9"},
      {:phoenix_live_view, "~> 1.2"},

      # Dev / test
      {:ex_quality, "~> 0.16", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end
end
