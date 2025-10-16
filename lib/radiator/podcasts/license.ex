defmodule Radiator.Podcasts.License do
  @moduledoc false

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshTranslation.Resource]

  alias Radiator.Cldr.AshTranslation

  postgres do
    table "licenses"
    repo Radiator.Repo
  end

  translations do
    public? true
    fields([:name])
    locales(AshTranslation.locale_names())
  end

  actions do
    defaults [:read, :create, :update, :destroy]
  end

  attributes do
    uuid_primary_key :id

    attribute :short_name, :string do
      description "The short name of the license"
      allow_nil? false
    end

    attribute :name, :string do
      description "The name of the license"
      allow_nil? false
    end

    attribute :url, :string do
      description "The URL of the license"
      allow_nil? false
    end

    relationships do
      has_many :podcasts, Radiator.Podcasts.Podcast do
        description "The podcasts that use this license"
        public? true
      end
    end

    timestamps()
  end
end
