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

  alias Radiator.Media
  alias Radiator.Directory.{Episode, Network}
  alias Radiator.AudioMeta.Chapter
  alias Radiator.Contribution

  schema "audios" do
    field :title, :string
    field :duration, :string
    field :published_at, :utc_datetime
    field :image, Media.AudioImage.Type

    has_many :episodes, Episode

    has_many :contributions, Contribution.AudioContribution
    has_many :contributors, through: [:contributions, :person]

    belongs_to :network, Network

    has_many :audio_files, Media.AudioFile
    has_many :chapters, Chapter

    has_many :permissions, {"audios_perm", Radiator.Perm.Permission}, foreign_key: :subject_id

    timestamps()
  end

  @doc false
  def changeset(audio, attrs) do
    audio
    |> cast(attrs, [:title, :duration, :published_at])
    |> cast_attachments(attrs, [:image], allow_paths: true, allow_urls: true)

    # todo: validate it belongs to _something_ / not a zombie
  end
end
