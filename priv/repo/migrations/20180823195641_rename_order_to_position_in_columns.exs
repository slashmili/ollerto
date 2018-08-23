defmodule Ollerto.Repo.Migrations.RenameOrderToPositionInColumns do
  use Ecto.Migration

  def change do
    rename(table(:columns), :order, to: :position)
  end
end
