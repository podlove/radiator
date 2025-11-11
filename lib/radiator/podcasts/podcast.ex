defmodule Radiator.Podcasts.Podcast do
  @moduledoc false

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "podcasts"
    repo Radiator.Repo
  end

  resource do
    description "A podcast"
  end

  @default_accept_attributes [
    :title,
    :subtitle,
    :summary,
    :mnemonic,
    :language,
    :itunes_type,
    :license_name,
    :license_url,
    :author,
    :itunes_category,
    :blocked,
    :explicit,
    :complete,
    :funding_url,
    :funding_description
  ]

  actions do
    defaults [:read, :destroy, :create, :update]

    default_accept @default_accept_attributes

    create :import do
      description "Import a podcast from external feed data"
      accept @default_accept_attributes ++ [:guid]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :guid, :string do
      description "The unique identifier for the podcast"
      allow_nil? false
      public? true
      default &Ash.UUID.generate/0
    end

    attribute :title, :string do
      description "A podcast's title"
      allow_nil? false
      public? true
    end

    attribute :subtitle, :string do
      description "A podcast's subtitle"
      public? true
    end

    attribute :summary, :string do
      description "A podcast's summary"
      public? true
      constraints max_length: 4000
    end

    attribute :mnemonic, :string do
      description "A short name"
      public? true
    end

    attribute :language, :string do
      description "The language of the podcast as an ISO 639-1"
      public? true
    end

    attribute :itunes_type, Radiator.Podcasts.ItunesPodcastType do
      description "The iTunes type of the podcast"
      allow_nil? false
      public? true
      default :episodic
    end

    attribute :license_name, :string do
      description "The name of the license"
      public? true
    end

    attribute :license_url, :string do
      description "The URL of the license"
      public? true
    end

    attribute :author, :string do
      description "The author of the podcast"
      public? true
    end

    attribute :itunes_category, {:array, :string} do
      description "The iTunes category"
      allow_nil? false
      public? true
      default []
      constraints max_length: 3
    end

    attribute :blocked, :boolean do
      description "Whether the podcast is blocked"
      allow_nil? false
      public? true
      default false
    end

    attribute :explicit, :boolean do
      description "Whether the podcast contains explicit content"
      allow_nil? false
      public? true
      default false
    end

    attribute :complete, :boolean do
      description "Whether the podcast is complete"
      allow_nil? false
      public? true
      default false
    end

    attribute :funding_url, :string do
      description "The URL of the donation page"
      public? true
    end

    attribute :funding_description, :string do
      description "The description of the donation"
      public? true
    end

    timestamps()
  end

  relationships do
    has_many :episodes, Radiator.Podcasts.Episode do
      description "The episodes of the podcast"
      public? true
    end

    belongs_to :license, Radiator.Podcasts.License do
      description "The license of the podcast"
      public? true
    end
  end
end
