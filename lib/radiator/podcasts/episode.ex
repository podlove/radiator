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
    :number,
    :guid,
    :season,
    :episode_type,
    :subtitle,
    :summary,
    :content_html,
    :author,
    :link,
    :published_at,
    :duration_seconds,
    :image_url,
    :enclosure_url,
    :enclosure_length,
    :enclosure_type,
    :chapters,
    :chapters_url,
    :chapters_type,
    :transcripts
  ]

  # `last_seen_in_feed_at` is the importer's bookkeeping, not client input.
  @feed_accept_attributes @default_accept_attributes ++ [:podcast_id, :last_seen_in_feed_at]

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

    # The importer's way in: a sync owns everything the feed supplies.
    create :upsert_from_feed do
      accept @feed_accept_attributes

      upsert? true
      upsert_identity :unique_guid_per_podcast
      upsert_fields {:replace_all_except, [:id, :inserted_at, :podcast_id, :guid]}
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string, allow_nil?: false
    attribute :number, :integer
    attribute :guid, :string
    attribute :season, :integer
    attribute :episode_type, Radiator.Podcasts.EpisodeType
    attribute :subtitle, :string
    attribute :summary, :string
    attribute :content_html, :string
    attribute :author, :string
    attribute :link, :string
    attribute :published_at, :utc_datetime_usec
    attribute :duration_seconds, :integer
    attribute :image_url, :string
    attribute :enclosure_url, :string
    attribute :enclosure_length, :integer
    attribute :enclosure_type, :string
    attribute :chapters, {:array, Radiator.Podcasts.Episode.Chapter}, default: []
    attribute :chapters_url, :string
    attribute :chapters_type, :string
    attribute :transcripts, {:array, Radiator.Podcasts.Episode.Transcript}, default: []
    attribute :last_seen_in_feed_at, :utc_datetime_usec

    timestamps()
  end

  relationships do
    belongs_to :podcast, Podcast, allow_nil?: false

    has_many :contributors, Radiator.Podcasts.EpisodeContributor
  end

  calculations do
    # Explicit about both nil cases: a hand-created episode was never in a feed
    # and must not read as missing from it.
    calculate :missing_from_feed?,
              :boolean,
              expr(
                not is_nil(last_seen_in_feed_at) and
                  not is_nil(podcast.last_imported_at) and
                  last_seen_in_feed_at < podcast.last_imported_at
              )
  end

  identities do
    # `nils_distinct?` stays `true`: hand-created episodes without a guid do
    # not collide, and the translator drops feed items without an identity.
    identity :unique_guid_per_podcast, [:podcast_id, :guid]
  end
end
