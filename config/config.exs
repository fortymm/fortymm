# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :fortymm,
  ecto_repos: [Fortymm.Repo]

# Configures the endpoint
config :fortymm, FortymmWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "TWh5E7TlFZr90uku12m6C7foLrSnsoZfIUGuk6uEeeq6WvOS6Y29LtlHfVvGoj65",
  render_errors: [view: FortymmWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Fortymm.PubSub,
  live_view: [signing_salt: "CL7qdSL1"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
