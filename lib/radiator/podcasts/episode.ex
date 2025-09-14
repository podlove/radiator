defmodule Radiator.Podcasts.Episode do
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "episodes"
    repo Radiator.Repo
  end

  actions do
    defaults [:read, :destroy, :create, :update]
    default_accept [:title, :subtitle, :summary, :number, :itunes_type, :duration_seconds]
  end

  attributes do
    uuid_primary_key :id

    attribute :guid, :uuid do
      description "The unique identifier for the episode"
      allow_nil? false
      public? true
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
      allow_nil? false
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

    attribute :duration_seconds, :integer do
      description "The duration of the episode in seconds"
      public? true
    end

    relationships do
      has_many :chapters, Radiator.Podcasts.Chapter do
        description "The chapters of the episode"
        public? true
        sort start_time_seconds: :asc
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
    identity :guid, [:guid]
    # TODO: identity for number, scoped to show and season
  end
end
