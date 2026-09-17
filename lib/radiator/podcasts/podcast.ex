defmodule Radiator.Podcasts.Podcast do
  @moduledoc """
  Domain interface for podcast related resources.
  """

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer,
    notifiers: [Ash.Notifier.PubSub],
    fragments: [
      Radiator.Podcasts.Podcast.Calculations,
      Radiator.Podcasts.Podcast.Policies,
      Radiator.Podcasts.Podcast.Sync
    ]

  alias Radiator.Accounts.User
  alias Radiator.Podcasts.Episode

  @default_accept_attributes [
    :title,
    :feed_url,
    :subtitle,
    :summary,
    :description,
    :link,
    :language,
    :author,
    :owner_name,
    :owner_email,
    :image_url,
    :copyright,
    :license,
    :license_url,
    :funding_url,
    :funding_text,
    :podcast_type,
    :explicit,
    :feed_guid,
    :categories
  ]

  postgres do
    table "podcasts"
    repo Radiator.Repo
  end

  actions do
    defaults [:read, :destroy]
    default_accept @default_accept_attributes

    create :create do
      validate present(:title)

      change relate_actor(:user)
    end

    create :import do
      accept [:feed_url, :sync_strategy]

      validate present(:feed_url)

      change relate_actor(:user)
      change set_attribute(:sync_status, :pending)
      change run_oban_trigger(:sync)
    end

    update :update do
      # An explicit action is not primary by default; `Ash.update!/2` needs one.
      primary? true

      accept @default_accept_attributes ++ [:sync_strategy]

      change Radiator.Podcasts.Podcast.Changes.ResetHttpCache
    end

    read :public_read do
      pagination offset?: true, keyset?: true, required?: false
    end
  end

  pub_sub do
    module RadiatorWeb.Endpoint
    prefix "podcast"

    publish_all :create, "created"
    publish_all :update, "updated"
    publish_all :destroy, "destroyed"
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string
    attribute :feed_url, :string
    attribute :subtitle, :string
    attribute :summary, :string
    attribute :description, :string
    attribute :link, :string
    attribute :language, :string
    attribute :author, :string
    attribute :owner_name, :string
    attribute :owner_email, :string
    attribute :image_url, :string
    attribute :copyright, :string
    attribute :license, :string
    attribute :license_url, :string
    attribute :funding_url, :string
    attribute :funding_text, :string
    attribute :podcast_type, Radiator.Podcasts.PodcastType
    attribute :explicit, :boolean
    attribute :feed_guid, :string
    attribute :categories, {:array, Radiator.Podcasts.Podcast.Category}, default: []

    timestamps()
  end

  relationships do
    belongs_to :user, User, allow_nil?: false

    # Newest first. Undated episodes go last; an item without a number must not
    # sit on top of the whole show.
    has_many :episodes, Episode, sort: [published_at: :desc_nils_last, number: :desc_nils_last]
  end
end
