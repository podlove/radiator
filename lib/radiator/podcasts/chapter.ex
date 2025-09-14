defmodule Radiator.Podcasts.Chapter do
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "chapters"
    repo Radiator.Repo
  end

  actions do
    defaults [:read, :destroy, :create, :update]
    default_accept [:start_time_seconds, :title, :link]
  end

  attributes do
    uuid_primary_key :id

    attribute :start_time_seconds, :integer do
      description "The start time of the chapter"
      public? true
      allow_nil? false
      constraints min: 0
    end

    attribute :title, :string do
      description "The title of the chapter"
      public? true
      allow_nil? false
    end

    attribute :link, :string do
      description "The link of the chapter"
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :episode, Radiator.Podcasts.Episode do
      description "The episode this chapter belongs to"
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :start_time, [:start_time_seconds, :episode_id]
  end
end
