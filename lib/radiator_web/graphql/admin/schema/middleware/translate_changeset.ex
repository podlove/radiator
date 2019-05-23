defmodule RadiatorWeb.GraphQL.Admin.Schema.Middleware.TranslateChangeset do
  @behaviour Absinthe.Middleware

  def call(%Absinthe.Resolution{errors: errors} = resolution, _config)
      when not is_nil(errors) and errors != [] do
    transformed_errors =
      Enum.map(errors, fn
        %Ecto.Changeset{} = changeset ->
          translated = RadiatorWeb.ChangesetView.translate_errors(changeset)

          translated
          |> Map.keys()
          |> Enum.map(&"#{&1} #{translated[&1]}")

        val ->
          val
      end)
      |> List.flatten()

    Absinthe.Resolution.put_result(resolution, {:error, transformed_errors})
  end

  def call(resolution, _config), do: resolution
end
