defmodule OllertoWeb.BoardsReslover do
  alias Ollerto.Boards

  def list_boards(_, _, %{context: %{current_user: current_user}}) do
    {:ok, Boards.list_boards(owner: current_user)}
  end

  def create_board(_, %{input: params}, %{context: %{current_user: current_user}}) do
    with {:ok, board} <- Boards.create_board(Map.put(params, :owner_id, current_user.id)) do
      {:ok, %{board: board}}
    end
  end

  def get_board(_, %{hashid: hashid}, %{context: %{current_user: current_user}}) do
    case Boards.get_board(owner: current_user, hashid: hashid) do
      nil -> {:error, %{message: "board is not found"}}
      board -> {:ok, board}
    end
  end
end
