defmodule Ollerto.Boards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "cards" do
    field :position, :float
    field :title, :string
    belongs_to :column, Ollerto.Boards.Column

    timestamps()
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:title, :position, :column_id])
    |> validate_required([:title, :position, :column_id])
  end
end
