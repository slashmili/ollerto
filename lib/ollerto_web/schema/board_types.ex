defmodule OllertoWeb.Schema.BoardTypes do
  use Absinthe.Schema.Notation

  object :board do
    field :id, :id
    field :name, :string
    field :hashid, :string
  end
end
