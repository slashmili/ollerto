defmodule OllertoWeb.Schema do
  use Absinthe.Schema
  alias OllertoWeb.AccountsReslover
  alias OllertoWeb.Schema.ChangesetErrorsMiddleware

  import_types __MODULE__.AccountTypes

  def middleware(middleware, _field, %{identifier: :mutation}) do
    middleware ++ [ChangesetErrorsMiddleware]
  end

  def middleware(middleware, _, _), do: middleware

  object :input_error do
    field :key, non_null(:string)
    field :message, non_null(:string)
  end

  mutation do
    field :register_user, :register_user_result do
      arg :input, non_null(:register_user_input)
      resolve &AccountsReslover.register_user/3
    end

    field :authenticate_user, :authenticate_user_result do
      arg :input, non_null(:authenticate_user_input)
      resolve &AccountsReslover.authenticate_user/3
    end
  end

  query do
    field :user_login, :user do
      resolve fn _, _, _ ->
        {:ok, %{id: "1", email: "TBD"}}
      end
    end
  end

  subscription do
    field :new_order, :user do
      arg :id, non_null(:id)

      config(fn args, sc ->
        IO.inspect(args)
        IO.inspect(sc)
        {:ok, topic: args.id}
      end)
    end
  end
end
