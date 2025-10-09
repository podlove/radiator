defmodule Radiator.Podcasts.Chapter do
  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "chapters"
    repo Radiator.Repo

    references do
      reference :episode, on_delete: :delete
    end
  end

  @default_accept_attributes [:start_time_ms, :title, :link]

  actions do
    defaults [:read, :destroy, :update]
    default_accept @default_accept_attributes

    create :create do
      accept @default_accept_attributes ++ [:episode_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :start_time_ms, :integer do
      description "The start time of the chapter in milliseconds"
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
    identity :start_time, [:start_time_ms, :episode_id] do
      eager_check? true
    end
  end
end
