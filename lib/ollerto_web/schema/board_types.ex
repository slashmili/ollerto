defmodule OllertoWeb.Schema.BoardTypes do
  use Absinthe.Schema.Notation

  object :board do
    field :id, :id
    field :name, :string
    field :hashid, :string
  end

  input_object :create_board_input do
    field :name, non_null(:string)
  end

  object :create_board_result do
    field :board, :board
    field :errors, list_of(:input_error)
  end
end
