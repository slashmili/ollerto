defmodule Ollerto.Ecto.HashidType do
  @behaviour Ecto.Type
  def type, do: :serial

  def cast(hashid) when is_binary(hashid) do
    val =
      [min_len: 4]
      |> Hashids.new()
      |> Hashids.decode(hashid)

    case val do
      {:ok, [id]} ->
        {:ok, id}

      _ ->
        :error
    end
  end

  def cast(_), do: :error

  def load(val) when is_integer(val) do
    hashid =
      [min_len: 4]
      |> Hashids.new()
      |> Hashids.encode(val)

    {:ok, hashid}
  end

  def load(_), do: :error

  def dump(val) when is_integer(val), do: {:ok, val}
  def dump(_), do: :error
end
