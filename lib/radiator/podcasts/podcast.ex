defmodule Radiator.Podcasts.Podcast do
  @moduledoc """
  Domain interface for podcast related resources.
  """

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Episode

  @default_accept_attributes [
    :title,
    :feed_url
  ]

  postgres do
    table "podcasts"
    repo Radiator.Repo
  end

  actions do
    defaults [:read, :update, :destroy]
    default_accept @default_accept_attributes

    create :create do
      validate present(:title)

      change relate_actor(:user)
    end

    create :import do
      accept [:feed_url]

      validate present(:feed_url)

      change relate_actor(:user)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string
    attribute :feed_url, :string

    timestamps()
  end

  relationships do
    belongs_to :user, User, allow_nil?: false

    has_many :episodes, Episode, sort: [number: :desc_nils_first]
  end

  calculations do
    calculate :display_title, :string, expr(if is_nil(title), do: feed_url, else: title)
  end
end
