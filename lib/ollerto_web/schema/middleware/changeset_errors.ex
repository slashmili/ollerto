defmodule OllertoWeb.Schema.ChangesetErrorsMiddleware do
  @behaviour Absinthe.Middleware

  def call(res, _) do
    case res do
      %{errors: [%Ecto.Changeset{} = changeset]} ->
        %{res | value: %{errors: transform_errors(changeset)}, errors: []}

      %{value: %{errors: _}} ->
        res

      %{value: value} ->
        %{res | value: Map.put(value || %{}, :errors, [])}
    end
  end

  defp transform_errors(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&format_error/1)
    |> Enum.map(fn {k, v} -> %{key: v, message: k} end)
  end

  defp format_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
