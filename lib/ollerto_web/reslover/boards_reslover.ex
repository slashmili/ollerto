defmodule OllertoWeb.BoardsReslover do
  alias Ollerto.Boards
  alias Ollerto.Accounts.User

  def list_boards(%User{} = user, _, _) do
    {:ok, Boards.list_boards(for_user: user)}
  end
end
