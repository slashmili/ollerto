defmodule OllertoWeb.Schema do
  use Absinthe.Schema
  alias OllertoWeb.{AccountsReslover, BoardsReslover}
  alias OllertoWeb.Schema.{ChangesetErrorsMiddleware, AuthorizeMiddleware}

  import_types __MODULE__.AccountTypes
  import_types __MODULE__.BoardTypes

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

    field :create_board, :create_board_result do
      description "Creates board for authorized user"
      arg :input, non_null(:create_board_input)
      middleware AuthorizeMiddleware
      resolve &BoardsReslover.create_board/3
    end
  end

  query do
    field :me, :user do
      resolve &AccountsReslover.me/3
    end

    field :boards, list_of(:board) do
      description "Lists boards for authorized user"
      middleware AuthorizeMiddleware
      resolve &BoardsReslover.list_boards/3
    end

    field :board, :board do
      description "Lookups a board by hashid."
      arg :hashid, non_null(:string)
      middleware AuthorizeMiddleware
      resolve &BoardsReslover.get_board/3
    end

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
