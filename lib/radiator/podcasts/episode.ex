defmodule Radiator.Podcasts.Episode do
  @moduledoc """
  Model specification for podcast episodes. Ash state machine is used to define the
  different states of an episode.
  """

  use Ash.Resource,
    otp_app: :radiator,
    domain: Radiator.Podcasts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStateMachine]

  alias Radiator.People.Persona
  alias Radiator.Podcasts.Chapter
  alias Radiator.Podcasts.EpisodeParticipant
  alias Radiator.Podcasts.Podcast
  alias Radiator.Podcasts.Track

  postgres do
    table "episodes"
    repo Radiator.Repo

    references do
      reference :podcast, on_delete: :delete
    end
  end

  state_machine do
    initial_states([:scheduling])
    default_initial_state(:scheduling)

    transitions do
      transition(:begin_scheduling, from: :creation, to: :scheduling)
      transition(:finalize_scheduling, from: :scheduling, to: :scheduled)
      transition(:back_to_scheduling, from: :scheduled, to: :scheduling)
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
    defaults [:read, :destroy]
    default_accept @default_accept_attributes

    create :create do
      accept @default_accept_attributes ++ [:podcast_id]

      argument :participants, {:array, :map}, allow_nil?: true

      change manage_relationship(:participants,
               use_identities: [:handle],
               on_no_match: {:create, :create},
               on_match: {:update, :update},
               on_lookup: :relate,
               on_missing: :unrelate
             )
    end

    create :import do
      description "Import an episode from external feed data"
      accept @default_accept_attributes ++ [:guid, :podcast_id]
    end

    update :update do
      require_atomic? false
      argument :participants, {:array, :map}, allow_nil?: true
      argument :add_participant, :struct, allow_nil?: true, constraints: [instance_of: Persona]
      argument :scheduling, :map, allow_nil?: true

      argument :remove_participant, :struct,
        allow_nil?: true,
        constraints: [instance_of: Persona]

      change manage_relationship(:participants,
               use_identities: [:handle],
               on_no_match: {:create, :create},
               on_match: {:update, :update},
               on_lookup: :relate,
               on_missing: :unrelate
             )

      change manage_relationship(:scheduling,
               on_no_match: {:create, :create},
               on_match: {:update, :update},
               on_lookup: :relate,
               on_missing: :unrelate
             )

      change manage_relationship(:add_participant, :participants, type: :append)
      change manage_relationship(:remove_participant, :participants, type: :remove)
    end

    update :begin_scheduling do
      description "Transition episode to scheduling state"
      change transition_state(:scheduling)
    end

    update :finalize_scheduling do
      description "Transition episode to scheduled state after scheduling is complete"
      accept [:publication_date]
      change transition_state(:scheduled)
    end

    update :back_to_scheduling do
      description "Reopen scheduling for an episode"
      change transition_state(:scheduling)
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

    timestamps()
  end

  relationships do
    belongs_to :podcast, Podcast do
      description "The podcast this episode belongs to"
      public? true
      allow_nil? false
    end

    has_many :chapters, Chapter do
      description "The chapters of the episode"
      public? true
      sort start_time_ms: :asc
    end

    many_to_many :participants, Persona do
      through EpisodeParticipant
      public? true
    end

    has_many :tracks, Track

    has_one :scheduling, Radiator.Podcasts.Episode.Scheduling do
      description "The scheduling information for this episode"
      public? true
    end
  end

  identities do
    identity :guid, [:guid] do
      eager_check? true
    end

    # HINT: add season_id to the identity when seasons are addeed
    identity :number, [:number, :podcast_id] do
      eager_check? true
    end
  end
end
