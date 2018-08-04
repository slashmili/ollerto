defmodule Ollerto.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field(:email, :string)
    field(:password_hash, :string)

    field(:password, :string, virtual: true)

    has_many(:boards, Ollerto.Boards.Board, foreign_key: :owner_id)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password_hash])
    |> validate_required([:email, :password_hash])
  end

  def register_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> unique_constraint(:email)
    |> put_pass_hash
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Pbkdf2.hashpwsalt(pass))

      _ ->
        changeset
    end
  end

  @spec valid_password?(%__MODULE__{}, String.t()) :: boolean
  def valid_password?(%__MODULE__{password_hash: digest}, password) do
    Comeonin.Pbkdf2.checkpw(password, digest)
  end
end
