defmodule Radiator.Directory.AudioPublication do
  use Ecto.Schema

  import Ecto.Changeset

  alias Radiator.Directory.{
    Network,
    Audio
  }

  schema "audio_publications" do
    field :publish_state, :string
    field :published_at, :utc_datetime

    belongs_to :network, Network
    belongs_to :audio, Audio

    timestamps()
  end

  def changeset(audio_publication, attrs) do
    audio_publication
    |> cast(attrs, [
      :publish_state
    ])
    |> maybe_set_published_at()
  end

  @doc """
  Importer is allowed to set publish date.
  """
  def import_changeset(audio_publication, attrs) do
    audio_publication
    |> cast(attrs, [
      :publish_state,
      :published_at
    ])
  end

  defp maybe_set_published_at(changeset) do
    {
      get_field(changeset, :publish_state),
      get_field(changeset, :published_at)
    }
    |> case do
      {:publish, nil} -> put_change(changeset, :published_at, DateTime.utc_now())
      _ -> changeset
    end
  end
end
