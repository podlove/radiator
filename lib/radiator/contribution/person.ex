defmodule Radiator.Contribution.Person do
  @moduledoc """
  TODO: Does this all fit into one context or should it be
        separate? People can stand on their own, without
        being used for contributions.
        AudioContribution could fit into AudioMeta.

        There are also different kinds of contributions:

        - podcast contributor
        - episode contributor
        - audio contributor

        Can we get away with audio + podcast?
        Or do we need episode as well?

  """
  use Ecto.Schema
  import Ecto.Changeset
  import Arc.Ecto.Changeset

  import Ecto.Query, warn: false

  alias Radiator.Auth.User
  alias Radiator.Media
  alias Radiator.Directory.Network

  schema "people" do
    field :name, :string
    field :display_name, :string
    field :nick, :string
    field :email, :string
    field :link, :string

    field :image, Media.PersonAvatar.Type

    belongs_to :user, User
    belongs_to :network, Network

    timestamps()
  end

  @doc false
  def changeset(person, attrs) do
    person
    |> cast(attrs, [:name, :display_name, :nick, :link, :email])
    |> validate_required([:display_name])
    |> cast_attachments(attrs, [:image], allow_paths: true, allow_urls: true)
  end

  @doc """
  Convenience accessor for image URL.
  """
  def image_url(%__MODULE__{} = subject) do
    Media.PersonAvatar.url({subject.image, subject})
  end
end
