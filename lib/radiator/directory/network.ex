defmodule Radiator.Directory.Network do
  use Ecto.Schema
  use Arc.Ecto.Schema

  import Ecto.Changeset

  alias Radiator.Directory.Podcast

  schema "networks" do
    field :image, Radiator.Media.NetworkImage.Type
    field :title, :string

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
    |> cast_attachments(attrs, [:image])
    |> validate_required([:title])
  end
end
