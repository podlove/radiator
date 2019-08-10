defmodule Radiator.Directory.Publication do
  use Radiator.Constants

  import Ecto.Changeset

  @doc """
  Set :published_at on publication if it has not been set yet.
  """
  def maybe_set_published_at(changeset) do
    {
      get_field(changeset, :publish_state),
      get_field(changeset, :published_at)
    }
    |> case do
      {:published, nil} ->
        put_change(changeset, :published_at, DateTime.utc_now() |> DateTime.truncate(:second))

      _ ->
        changeset
    end
  end

  def validate_publish_state(changeset) do
    validate_inclusion(changeset, :publish_state, @publish_states,
      message: "is invalid. must be one of: #{Enum.join(@publish_states, ", ")}"
    )
  end
end
