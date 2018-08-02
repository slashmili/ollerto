defmodule OllertoWeb.AccountsReslover do
  alias Ollerto.Accounts

  def register_user(_, %{input: params}, _) do
    with {:ok, new_user} <- Accounts.create_user(params) do
      {:ok, %{user: new_user}}
    end
  end

  def authenticate_user(_, %{input: params}, _) do
    with {:ok, user} <- Accounts.authenticate(params[:email], params[:password]) do
      token = sign(%{id: user.id})
      {:ok, %{token: token, user: user}}
    else
      _ ->
        {:error, "Incorrect User or Password"}
    end
  end

  # TODO: secure the salt!
  @user_salt "122112112"
  @max_age 7 * 24 * 3600
  defp sign(data) do
    Phoenix.Token.sign(OllertoWeb.Endpoint, @user_salt, data)
  end

  defp verify(token) do
    Phoenix.Token.verify(OllertoWeb.Endpoint, @user_salt, token, max_age: @max_age)
  end
end
