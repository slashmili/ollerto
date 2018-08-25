defmodule Ollerto.Boards do
  @moduledoc """
  The Boards context.
  """

  import Ecto.Query, warn: false
  alias Ollerto.Repo

  alias Ollerto.Boards.Board

  @doc """
  Returns the list of boards.

  ## Examples

      iex> list_boards()
      [%Board{}, ...]
      iex> list_boards(for_user: user)
      [%Board{}, ...]


  """
  def list_boards do
    Repo.all(Board)
  end

  def list_boards(owner: user) do
    Repo.all(from(b in Board, where: b.owner_id == ^user.id))
  end

  @doc """
  Gets a single board.

  Raises `Ecto.NoResultsError` if the Board does not exist.

  ## Examples

      iex> get_board!(123)
      %Board{}

      iex> get_board!(456)
      ** (Ecto.NoResultsError)

  """
  def get_board!(id), do: Repo.get!(Board, id)

  @doc """
  Gets a single board using provided criteria
  """
  def get_board(clauses) when is_list(clauses) do
    clauses
    |> Map.new()
    |> get_board
  end

  def get_board(%{owner: %{id: owner_id}} = clauses) do
    clauses
    |> Map.drop([:owner])
    |> Map.put(:owner_id, owner_id)
    |> get_board
  end

  def get_board(clauses) when is_map(clauses), do: Repo.get_by(Board, clauses)

  @doc """
  Creates a board.

  ## Examples

      iex> create_board(%{field: value})
      {:ok, %Board{}}

      iex> create_board(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_board(attrs \\ %{}) do
    %Board{}
    |> Board.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a board.

  ## Examples

      iex> update_board(board, %{field: new_value})
      {:ok, %Board{}}

      iex> update_board(board, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_board(%Board{} = board, attrs) do
    board
    |> Board.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Board.

  ## Examples

      iex> delete_board(board)
      {:ok, %Board{}}

      iex> delete_board(board)
      {:error, %Ecto.Changeset{}}

  """
  def delete_board(%Board{} = board) do
    Repo.delete(board)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking board changes.

  ## Examples

      iex> change_board(board)
      %Ecto.Changeset{source: %Board{}}

  """
  def change_board(%Board{} = board) do
    Board.changeset(board, %{})
  end

  alias Ollerto.Boards.Column

  @doc """
  Returns the list of columns.

  ## Examples

      iex> list_columns()
      [%Column{}, ...]

  """
  def list_columns do
    Repo.all(Column)
  end

  def list_columns(board: board) do
    list_columns(board_id: board.id)
  end

  def list_columns(board_id: board_id) do
    Repo.all(from(c in Column, where: c.board_id == ^board_id, order_by: [:position]))
  end

  @doc """
  Gets a single column.

  Raises `Ecto.NoResultsError` if the Column does not exist.

  ## Examples

      iex> get_column!(123)
      %Column{}

      iex> get_column!(456)
      ** (Ecto.NoResultsError)

  """
  def get_column!(id), do: Repo.get!(Column, id)

  @doc """
  Creates a column.

  ## Examples

      iex> create_column(%{field: value})
      {:ok, %Column{}}

      iex> create_column(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_column(attrs \\ %{}) do
    %Column{}
    |> Column.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a column.

  ## Examples

      iex> update_column(column, %{field: new_value})
      {:ok, %Column{}}

      iex> update_column(column, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_column(%Column{} = column, attrs) do
    column
    |> Column.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Column.

  ## Examples

      iex> delete_column(column)
      {:ok, %Column{}}

      iex> delete_column(column)
      {:error, %Ecto.Changeset{}}

  """
  def delete_column(%Column{} = column) do
    Repo.delete(column)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking column changes.

  ## Examples

      iex> change_column(column)
      %Ecto.Changeset{source: %Column{}}

  """
  def change_column(%Column{} = column) do
    Column.changeset(column, %{})
  end

  @doc """
  Gets the highest position value in columns for given board
  """
  def get_latest_column_position(board) do
    q =
      from c in Column,
        select: [c.position],
        where: c.board_id == ^board.id,
        limit: 1,
        order_by: [desc: :position]

    q
    |> Repo.all()
    |> List.first()
    |> Nily.map(&List.first/1)
    |> Nily.withDefault(0)
  end

  alias Ollerto.Boards.Card

  @doc """
  Returns the list of cards.

  ## Examples

      iex> list_cards()
      [%Card{}, ...]

  """
  def list_cards do
    Repo.all(Card)
  end

  def list_cards(column: column) do
    list_cards(column_id: column.id)
  end

  def list_cards(column_id: column_id) do
    Repo.all(from(c in Card, where: c.column_id == ^column_id, order_by: [:position]))
  end

  @doc """
  Gets a single card.

  Raises `Ecto.NoResultsError` if the Card does not exist.

  ## Examples

      iex> get_card!(123)
      %Card{}

      iex> get_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_card!(id), do: Repo.get!(Card, id)

  @doc """
  Creates a card.

  ## Examples

      iex> create_card(%{field: value})
      {:ok, %Card{}}

      iex> create_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_card(attrs \\ %{}) do
    %Card{}
    |> Card.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a card.

  ## Examples

      iex> update_card(card, %{field: new_value})
      {:ok, %Card{}}

      iex> update_card(card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_card(%Card{} = card, attrs) do
    card
    |> Card.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Card.

  ## Examples

      iex> delete_card(card)
      {:ok, %Card{}}

      iex> delete_card(card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_card(%Card{} = card) do
    Repo.delete(card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking card changes.

  ## Examples

      iex> change_card(card)
      %Ecto.Changeset{source: %Card{}}

  """
  def change_card(%Card{} = card) do
    Card.changeset(card, %{})
  end

  @doc """
  Gets the highest position value in columns for given board
  """
  def get_latest_card_position(column) do
    q =
      from c in Card,
        select: [c.position],
        where: c.column_id == ^column.id,
        limit: 1,
        order_by: [desc: :position]

    q
    |> Repo.all()
    |> List.first()
    |> Nily.map(&List.first/1)
    |> Nily.withDefault(0)
  end
end
