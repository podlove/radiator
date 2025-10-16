defmodule Radiator.Podcasts.Episode do
  @moduledoc false

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "episodes"
    repo Radiator.Repo

    references do
      reference :show, on_delete: :delete
    end
  end

  @default_accept_attributes [
    :title,
    :subtitle,
    :summary,
    :number,
    :itunes_type,
    :publication_date,
    :duration_ms
  ]

  actions do
    defaults [:read, :destroy, :update]
    default_accept @default_accept_attributes

    create :create do
      accept @default_accept_attributes ++ [:show_id]
    end

    create :import do
      description "Import an episode from external feed data"
      accept @default_accept_attributes ++ [:guid, :show_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :guid, :string do
      description "The unique identifier for the episode"
      allow_nil? false
      public? true
      default &Ash.UUID.generate/0
    end

    attribute :title, :string do
      description "An episode's title"
      allow_nil? false
      public? true
    end

    attribute :subtitle, :string do
      description "An episode's subtitle"
      public? true
    end

    attribute :summary, :string do
      description "An episode's summary"
      public? true
      constraints max_length: 4000
    end

    attribute :number, :integer do
      description "An episode's number"
      allow_nil? true
      public? true
    end

    attribute :itunes_type, Radiator.Podcasts.ItunesEpisodeType do
      description "The iTunes type of the episode"
      allow_nil? false
      public? true
      default :full
    end

    attribute :publication_date, :utc_datetime do
      description "The date and time the episode was published"
      public? true
    end

    attribute :duration_ms, :integer do
      description "The duration of the episode in milliseconds"
      public? true
    end

    relationships do
      has_many :chapters, Radiator.Podcasts.Chapter do
        description "The chapters of the episode"
        public? true
        sort start_time_ms: :asc
      end
    end

    timestamps()
  end

  relationships do
    belongs_to :show, Radiator.Podcasts.Show do
      description "The show this episode belongs to"
      public? true
      allow_nil? false
    end
  end

  identities do
    identity :guid, [:guid] do
      eager_check? true
    end

    # TODO: add season_id to the identity when seasons are addeed
    identity :number, [:number, :show_id] do
      eager_check? true
    end
  end
end
