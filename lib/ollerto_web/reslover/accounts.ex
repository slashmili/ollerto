defmodule OllertoWeb.AccountsReslover do
  alias Ollerto.Accounts

  def register_user(_, %{input: params}, _) do
    with {:ok, new_user} <- Accounts.create_user(params) do
      {:ok, %{user: new_user}}
    end
  end
end
