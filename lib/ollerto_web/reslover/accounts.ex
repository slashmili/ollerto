defmodule OllertoWeb.AccountsReslover do
  alias Ollerto.Accounts
  alias OllertoWeb.ErrorHelpers

  def register_user(_, %{input: params}, _) do
    case Accounts.create_user(params) do
      {:error, changeset} ->
        {:ok, %{errors: ErrorHelpers.error_details(changeset)}}

      {:ok, new_user} ->
        {:ok, %{user: new_user}}
    end
  end
end
