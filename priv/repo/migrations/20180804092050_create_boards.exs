defmodule Ollerto.Repo.Migrations.CreateBoards do
  use Ecto.Migration

  def change do
    create table(:boards, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:hashid, :serial)
      add(:owner_id, references(:users, on_delete: :nothing, type: :binary_id), null: false)

      timestamps()
    end

    create(index(:boards, [:owner_id]))
    unique_index(:boards, [:hashid])
  end
end
