defmodule OllertoWeb.BoardsReslover do
  alias Ollerto.Boards
  alias Ollerto.Boards.{Board, Column}

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

  def list_columns(%Board{} = board, _, _) do
    {:ok, Boards.list_columns(board: board)}
  end

  def create_column(_, %{input: params}, _) do
    # TODO: check if user owns the board
    board = Boards.get_board!(params.board_id)
    position = Boards.get_latest_column_position(board)
    params = Map.put(params, :position, position + 1024.1)

    with {:ok, column} <- Boards.create_column(params) do
      Absinthe.Subscription.publish(OllertoWeb.Endpoint, %{action: :created, column: column},
        board_column_event: board.hashid
      )

      {:ok, %{column: column}}
    end
  end

  def update_column(_, %{input: params}, _) do
    # TODO: check if user owns the board
    board = Boards.get_board!(params.board_id)
    column = Boards.get_column!(params.id)

    with {:ok, column} <- Boards.update_column(column, params) do
      Absinthe.Subscription.publish(OllertoWeb.Endpoint, %{action: :updated, column: column},
        board_column_event: board.hashid
      )

      {:ok, %{column: column}}
    end
  end

  def create_card(_, %{input: params}, _) do
    # TODO: check if user owns the board
    column = Boards.get_column!(params.column_id)
    board = Boards.get_board!(column.board_id)
    position = Boards.get_latest_card_position(column)
    params = Map.put(params, :position, position + 1024.1)

    with {:ok, card} <- Boards.create_card(params) do
      Absinthe.Subscription.publish(OllertoWeb.Endpoint, %{action: :created, card: card},
        board_column_event: board.hashid
      )

      {:ok, %{card: card}}
    end
  end

  def list_cards(%Column{} = column, _, _) do
    {:ok, Boards.list_cards(column: column)}
  end
end
