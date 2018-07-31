defmodule OllertoWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation

  object :user do
    field :id, :id
    field :email, :string
  end

  input_object :user_register_input do
    field :email, non_null(:string)
    field :password, non_null(:string)
  end

  object :user_register_result do
    field :user, :user
    field :errors, list_of(:input_error)
  end
end
