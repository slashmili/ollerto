defmodule Nily do
  @type element :: any
  @spec map(element | nil, (element -> any())) :: element | nil
  def map(nil, _), do: nil

  def map(value, func), do: func.(value)

  @spec withDefault(element | nil, element) :: element
  def withDefault(nil, default), do: default
  def withDefault(value, _), do: value

  @spec andThen(element | nil, (element -> any())) :: element | nil
  def andThen(nil, _), do: nil
  def andThen(value, func), do: func.(value)
end
