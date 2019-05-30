defmodule Radiator.Directory.Network do
  use Ecto.Schema

  import Ecto.Changeset
  import Arc.Ecto.Changeset

  alias Radiator.Directory.{Podcast, TitleSlug}

  schema "networks" do
    field :image, Radiator.Media.NetworkImage.Type
    field :title, :string
    field :slug, TitleSlug.Type

    has_many :podcasts, Podcast

    has_many :attachments,
             {"network_attachments", Radiator.Media.Attachment},
             foreign_key: :subject_id

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
end
