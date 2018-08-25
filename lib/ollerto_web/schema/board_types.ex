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
    field :position, :integer
    field :name, :string
  end

  object :card do
    field :id, :id
    field :position, :float
    field :title, :string
    field :column_id, :id
  end

  input_object :create_board_input do
    field :name, non_null(:string)
  end

  object :create_board_result do
    field :board, :board
    field :errors, list_of(:input_error)
  end

  input_object :create_column_input do
    field :name, non_null(:string)
    field :board_id, non_null(:id)
    field :position, :float
  end

  object :create_column_result do
    field :column, :column
    field :errors, list_of(:input_error)
  end

  input_object :update_column_position_input do
    field :id, non_null(:id)
    field :board_id, non_null(:id)
    field :position, non_null(:float)
  end

  object :update_column_result do
    field :column, :column
    field :errors, list_of(:input_error)
  end

  input_object :create_card_input do
    field :title, non_null(:string)
    field :column_id, non_null(:id)
    field :position, :float
  end

  object :create_card_result do
    field :card, :card
    field :errors, list_of(:input_error)
  end
end
