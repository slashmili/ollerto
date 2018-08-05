defmodule OllertoWeb.BoardsReslover do
  alias Ollerto.Boards
  alias Ollerto.Accounts.User

  def list_boards(_, _, %{context: %{current_user: current_user}}) do
    {:ok, Boards.list_boards(for_user: current_user)}
  end

  def create_board(_, %{input: params}, %{context: %{current_user: current_user}}) do
    with {:ok, board} <- Boards.create_board(Map.put(params, :owner_id, current_user.id)) do
      {:ok, %{board: board}}
    end
  end
end
