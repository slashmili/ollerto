defmodule Ollerto.Boards.Board do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "boards" do
    field :hashid, Ollerto.Ecto.HashidType, read_after_writes: true
    field :name, :string

    belongs_to :owner, Ollerto.Accounts.User

    timestamps()
  end

  @doc """
  Build changeset

      user
      |> Ecto.build_assoc(:boards)
      |> Ollerto.Boards.Board.changeset(%{"name" => "asd"})
  """
  def changeset(board, attrs) do
    board
    |> cast(attrs, [:name, :owner_id])
    |> validate_required([:name, :owner_id])
    |> foreign_key_constraint(:owner_id)
  end
end
