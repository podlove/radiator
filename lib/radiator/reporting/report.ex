defmodule Radiator.Reporting.Report do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Tracking.Download
  alias Radiator.Reporting.Report

  schema "reports" do
    # network, podcast, episode, audio_publication
    field :subject_type, :string
    field :subject, :integer
    # total, month, day[, relative]
    # maybe something separate for relative makes more sense
    field :time_type, :string
    field :time, :string

    # metrics
    field :downloads, :integer
    field :listeners, :integer
    field :location, :string
    field :user_agents, :map

    timestamps()
  end

end
