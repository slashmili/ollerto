# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ollerto,
  ecto_repos: [Ollerto.Repo]

# Configures the endpoint
config :ollerto, OllertoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "PdggiX5wAnpoGEXwqlpU4nG55wF3YfPiP84Y0qIuxHRgi50tZu8n4lPMffDHj6xA",
  render_errors: [view: OllertoWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Ollerto.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
