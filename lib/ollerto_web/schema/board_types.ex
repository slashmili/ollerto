defmodule OllertoWeb.Schema.BoardTypes do
  use Absinthe.Schema.Notation
  alias OllertoWeb.BoardsReslover

  object :board do
    field :id, :id
    field :name, :string
    field :hashid, :string

    field :columns, list_of(:column) do
      resolve &BoardsReslover.list_columns/3
    end
  end

  object :column do
    field :id, :id
    field :order, :integer
    field :name, :string
  end

  input_object :create_board_input do
    field :name, non_null(:string)
  end

  object :create_board_result do
    field :board, :board
    field :errors, list_of(:input_error)
  end
end
