defmodule OllertoWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation
  alias OllertoWeb.BoardsReslover

  object :user do
    field :id, :id
    field :email, :string

    field :boards, list_of(:board) do
      resolve &BoardsReslover.list_boards/3
    end
  end

  input_object :register_user_input do
    field :email, non_null(:string)
    field :password, non_null(:string)
  end

  object :register_user_result do
    field :user, :user
    field :errors, list_of(:input_error)
  end

  input_object :authenticate_user_input do
    field :email, non_null(:string)
    field :password, non_null(:string)
  end

  object :authenticate_user_result do
    field :token, non_null(:string)
    field :user, :user
  end
end
