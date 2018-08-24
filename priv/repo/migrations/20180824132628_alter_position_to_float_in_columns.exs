defmodule Ollerto.Repo.Migrations.AlterPositionToFloatInColumns do
  use Ecto.Migration

  def change do
    alter table(:columns) do
      modify(:position, :float)
    end
  end
end
