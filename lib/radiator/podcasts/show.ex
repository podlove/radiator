defmodule Radiator.Podcasts.Show do
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "shows"
    repo Radiator.Repo
  end

  resource do
    description "A show"
  end

  actions do
    defaults [:read, :destroy, :create, :update]
    default_accept [:title]
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      description "A show's title"
      allow_nil? false
      public? true
    end

    attribute :subtitle, :string do
      description "A show's subtitle"
      public? true
    end

    attribute :summary, :string do
      description "A show's summary"
      public? true
      constraints max_length: 4000
    end

    attribute :nmemonic, :string do
      description "A short name"
      public? true
    end

    attribute :language, :string do
      description "The language of the show as an ISO 639-1"
      public? true
    end

    attribute :itunes_type, Radiator.Podcasts.ItunesShowType do
      description "The iTunes podcast type"
      public? true
      default :serial
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
      description "The author of the show"
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
      description "Whether the show is blocked"
      allow_nil? false
      public? true
      default false
    end

    attribute :explicit, :boolean do
      description "Whether the show is explicit"
      allow_nil? false
      public? true
      default false
    end

    attribute :complete, :boolean do
      description "Whether the show is complete"
      allow_nil? false
      public? true
      default false
    end

    attribute :donation_url, :string do
      description "The URL of the donation page"
      public? true
    end

    attribute :donation_description, :string do
      description "The description of the donation"
      public? true
    end

    timestamps()
  end
end
