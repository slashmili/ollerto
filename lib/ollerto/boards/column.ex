defmodule Ollerto.Boards.Column do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "columns" do
    field :name, :string
    field :position, :integer, default: 0
    field :board_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(column, attrs) do
    column
    |> cast(attrs, [:name, :position, :board_id])
    |> validate_required([:name, :position, :board_id])
  end
end
