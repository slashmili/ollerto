defmodule OllertoWeb.PageController do
  use OllertoWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
