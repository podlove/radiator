defmodule Radiator.Directory.Audio do
  @moduledoc """
  Audio Meta Object.

  An Audio contains all data required to generate a web player: file references
  and audio metadata.

  An Audio belongs to one or many episodes, or stand on its own in a network.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Media
  alias Radiator.Directory.{Episode, Network}
  alias Radiator.EpisodeMeta.Chapter

  # todo: audio image
  # todo: audio file
  schema "audios" do
    field :title, :string
    field :duration, :string
    field :published_at, :utc_datetime
    # field :image, Radiator.Media.EpisodeImage.Type

    has_many :episodes, Episode
    belongs_to :network, Network

    has_many :audio_files, Media.AudioFile
    has_many :chapters, Chapter

    timestamps()
  end

  @doc false
  def changeset(audio, attrs) do
    audio
    |> cast(attrs, [:title, :duration, :published_at])

    # todo: validate it belongs to _something_ / not a zombie
  end
end
