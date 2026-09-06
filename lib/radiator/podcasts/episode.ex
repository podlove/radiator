defmodule Radiator.Podcasts.Episode do
  @moduledoc """
  Model specification for podcast episodes. Ash state machine is used to define the
  different states of an episode.
  """

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer

  alias Radiator.Podcasts.Podcast

  @default_accept_attributes [
    :title,
    :number
  ]

  postgres do
    table "episodes"
    repo Radiator.Repo

    references do
      reference :podcast, on_delete: :delete, index?: true
    end
  end

  actions do
    defaults [:read, :update, :destroy]
    default_accept @default_accept_attributes

    create :create do
      accept @default_accept_attributes ++ [:podcast_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string, allow_nil?: false
    attribute :number, :integer

    timestamps()
  end

  relationships do
    belongs_to :podcast, Podcast, allow_nil?: false
  end
end
