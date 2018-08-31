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
    plug OllertoWeb.Context
  end

  scope "/api" do
    pipe_through :api

    forward "/v1/graphql", Absinthe.Plug.GraphiQL,
      schema: OllertoWeb.Schema,
      socket: OllertoWeb.UserSocket
  end

  scope "/", OllertoWeb do
    # Use the default browser stack
    pipe_through :browser

    get "/*path", PageController, :index
  end
end
