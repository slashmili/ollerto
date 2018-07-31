defmodule OllertoWeb.Router do
  use OllertoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OllertoWeb do
    # Use the default browser stack
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  Absinthe.Plug.GraphiQL

  scope "/api" do
    pipe_through :api

    forward "/graphql", Absinthe.Plug.GraphiQL,
      schema: OllertoWeb.Schema,
      interface: :simple
  end
end
