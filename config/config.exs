# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :rune, RuneWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+1A64Ff/ZgTEx1/6QgdetQttph2yZ0HZg7kccrcim6VqlhuY81KCGBw5toH05SQI",
  render_errors: [view: RuneWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Rune.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :mojito,
  timeout: 5000,
  pool_opts: [
    size: 10,
    destinations: [
      "explorer.binance.org:443": [
        size: 20,
        max_overflow: 20,
        pools: 10
      ]
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
