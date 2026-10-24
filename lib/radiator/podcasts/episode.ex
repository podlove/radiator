defmodule Radiator.Podcasts.Episode do
  @moduledoc """
  Model specification for podcast episodes.

  An episode moves through a small lifecycle (`state`): a hand-created episode
  starts in `:scheduling`, where its recording date is found, and becomes
  `:scheduled` once a date is chosen. Episodes that come from a feed are
  already `:published`. The scheduling transitions are driven by the episode's
  scheduling, never by the user directly.
  """

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine]

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

  state_machine do
    initial_states [:scheduling, :published]
    default_initial_state :scheduling

    transitions do
      transition :finalize_scheduling, from: :scheduling, to: :scheduled
      transition :back_to_scheduling, from: :scheduled, to: :scheduling
    end
  end

  actions do
    defaults [:read, :destroy]
    default_accept @default_accept_attributes

    # The contributors arrive as the complete list: entries with an id are
    # updated, new ones created, and those left out removed. Newly added
    # contributors with an account are mailed after commit.
    create :create do
      accept @default_accept_attributes ++ [:podcast_id]

      argument :contributors, {:array, :map}

      change manage_relationship(:contributors, type: :direct_control)
      change Radiator.Podcasts.Episode.Changes.NotifyNewContributors
    end

    update :update do
      primary? true
      require_atomic? false

      argument :contributors, {:array, :map}

      change manage_relationship(:contributors, type: :direct_control)
      change Radiator.Podcasts.Episode.Changes.NotifyNewContributors
    end

    # The importer's way in: a sync owns everything the feed supplies.
    create :upsert_from_feed do
      accept @feed_accept_attributes

      upsert? true
      upsert_identity :unique_guid_per_podcast
      upsert_fields {:replace_all_except, [:id, :inserted_at, :podcast_id, :guid]}

      # Whatever is in the feed has been published, whatever state it had here.
      change set_attribute(:state, :published)
    end

    update :finalize_scheduling do
      description "A recording date was chosen."
      accept []
      change transition_state(:scheduled)
    end

    update :back_to_scheduling do
      description "The chosen recording date was given up; the search starts again."
      accept []
      change transition_state(:scheduling)
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

    has_one :scheduling, Radiator.Podcasts.Episode.Scheduling
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
