defmodule OllertoWeb.Context do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, data} <- IO.inspect(OllertoWeb.AccountsReslover.verify(token)),
         %{} = user <- get_user_data(data) do
      %{current_user: user}
    else
      _ -> %{}
    end
  end

  defp get_user_data(%{id: id}) do
    Ollerto.Accounts.get_user!(id)
  end
end
