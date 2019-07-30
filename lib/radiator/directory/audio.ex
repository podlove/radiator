defmodule Radiator.Directory.Audio do
  @moduledoc """
  Audio Meta Object.

  An Audio contains all data required to generate a web player: file references
  and audio metadata.

  An Audio belongs to one or many episodes, or stand on its own in a network.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Arc.Ecto.Changeset
  import Ecto.Query, warn: false

  alias __MODULE__
  alias Radiator.Media
  alias Radiator.AudioMeta.Chapter
  alias Radiator.Contribution

  alias Radiator.Directory.{
    Episode,
    Podcast,
    AudioPublication
  }

  schema "audios" do
    field :title, :string
    field :duration, :integer
    field :image, Media.AudioImage.Type

    has_many :episodes, Episode
    has_one :audio_publication, AudioPublication

    has_many :contributions, Contribution.AudioContribution
    has_many :contributors, through: [:contributions, :person]

    has_many :audio_files, Media.AudioFile
    has_many :chapters, Chapter

    timestamps()
  end

  @doc false
  def changeset(audio, attrs) do
    audio
    |> cast(attrs, [:title, :duration])
    |> cast_attachments(attrs, [:image], allow_paths: true, allow_urls: true)

    # todo: validate it belongs to _something_ / not a zombie
  end

  @doc """
  Convenience accessor for image URL.
  Use `podcast: podcast` to get podcast image if there is no audio image
  """
  def image_url(audio = %Audio{}, opts \\ []) do
    with url when is_binary(url) <- Media.AudioImage.url({audio.image, audio}) do
      url
    else
      _ ->
        case opts[:podcast] do
          podcast = %Podcast{} ->
            Podcast.image_url(podcast)

          _ ->
            nil
        end
    end
  end
end
