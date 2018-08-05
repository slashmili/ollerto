defmodule OllertoWeb.Schema.AuthorizeMiddleware do
  @behaviour Absinthe.Middleware

  def call(resolution, _) do
    with %{current_user: _} <- resolution.context do
      resolution
    else
      _ ->
        Absinthe.Resolution.put_result(resolution, {:error, "unauthorized"})
    end
  end
end
