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

    field :create_column, :create_column_result do
      description "Creates column for authorized user"
      arg :input, non_null(:create_column_input)
      middleware AuthorizeMiddleware
      resolve &BoardsReslover.create_column/3
    end

    field :create_card, :create_card_result do
      description "Creates card for authorized user"
      arg :input, non_null(:create_card_input)
      middleware AuthorizeMiddleware
      resolve &BoardsReslover.create_card/3
    end

    field :update_column_position, :update_column_result do
      description "Updates column's position for authorized user"
      arg :input, non_null(:update_column_position_input)
      middleware AuthorizeMiddleware
      resolve &BoardsReslover.update_column/3
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

  object :column_event do
    field :action, :string
    field :column, :column
  end

  subscription do
    field :board_column_event, :column_event do
      arg :board_hashid, non_null(:string)

      config(fn args, _sc ->
        {:ok, topic: args.board_hashid}
      end)
    end

    field :board, :board do
      arg :hashid, non_null(:string)

      config(fn args, sc ->
        IO.inspect(args)
        IO.inspect(sc)
        {:ok, topic: args.hashid}
      end)

      trigger(:updated_board,
        topic: fn
          %{updated: board}, _ -> [board.hashid]
          _, _ -> []
        end
      )

      resolve fn root, _, _ ->
        IO.inspect(root)
        {:ok, root}
      end
    end
  end
end
