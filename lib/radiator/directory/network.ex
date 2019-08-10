defmodule Radiator.Directory.Network do
  use Ecto.Schema

  import Ecto.Changeset
  import Arc.Ecto.Changeset

  alias __MODULE__

  alias Radiator.Directory.{
    Podcast,
    TitleSlug,
    AudioPublication
  }

  alias Radiator.Contribution.Person
  alias Radiator.Media.NetworkImage

  schema "networks" do
    field :image, NetworkImage.Type
    field :title, :string
    field :slug, TitleSlug.Type

    has_many :podcasts, Podcast
    has_many :audio_publications, AudioPublication
    has_many :people, Person
    has_many :permissions, {"networks_perm", Radiator.Perm.Permission}, foreign_key: :subject_id

    timestamps()
  end

  @doc false
  def changeset(network, attrs) do
    network
    |> cast(attrs, [:title])
    |> cast_attachments(attrs, [:image], allow_paths: true, allow_urls: true)
    |> validate_required([:title])
  end

  @doc false
  def creation_changeset(network, attrs) do
    network
    |> changeset(attrs)
    |> TitleSlug.maybe_generate_slug()
    |> TitleSlug.unique_constraint()
  end

  @doc """
  Convenience accessor for image URL.
  """
  def image_url(%Network{} = network) do
    NetworkImage.url({network.image, network})
  end
end
