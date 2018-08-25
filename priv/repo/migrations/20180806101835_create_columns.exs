defmodule Ollerto.Repo.Migrations.CreateColumns do
  use Ecto.Migration

  def change do
    create table(:columns, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:posiotion, :float)
      add(:board_id, references(:boards, on_delete: :delete_all, type: :binary_id))

      timestamps()
    end

    create(index(:columns, [:board_id]))
  end
end
