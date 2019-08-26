defmodule Radiator.Reporting.Report do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Tracking.Download
  alias Radiator.Reporting.Report

  alias Radiator.Directory.{
    Network,
    Podcast,
    Episode,
    AudioPublication
  }

  # TODO: use jobs (in generate I think) before I postpone it for too long

  @primary_key {:uid, :string, autogenerate: false}
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

  def downloads_changeset(report, attrs) do
    report
    |> cast(attrs, [:uid, :subject_type, :subject, :time_type, :time, :downloads])
    |> validate_required([:uid, :subject_type, :subject, :time_type, :downloads])
  end

  # think about the general steps we have for all reports:
  # - calculate: calculates and returns requested value
  # - generate: calculates and persists requested value
  # - either "generate" is only available as a job or there needs to be
  #   another container for generate, but as a job
  #
  # this already looks very repetitive but needs macros to DRY up.
  # needs some thought how far into DRYness we want to push this
  # using macro magic. Any action taken should improve maintainability,
  # readability and/or flexibility.

  @doc """
  Generate all total downloads numbers.

  For:
    - all Networks
    - all Podcasts
    - all Episodes
    - all AudioPublications

  """
  def generate_all_total_downloads do
    [
      Repo.all(Network) |> Enum.map(&{:network, &1.id}),
      Repo.all(Podcast) |> Enum.map(&{:podcast, &1.id}),
      Repo.all(Episode) |> Enum.map(&{:episode, &1.id}),
      Repo.all(AudioPublication) |> Enum.map(&{:audio_publication, &1.id})
    ]
    |> List.flatten()
    |> Enum.each(fn subject -> generate(subject, :total, :downloads) end)
  end

  def generate({:podcast, podcast_id}, :total, :downloads) do
    value = calculate({:podcast, podcast_id}, :total, :downloads)

    %Report{}
    |> Report.downloads_changeset(%{
      subject_type: "podcast",
      subject: podcast_id,
      time_type: "total",
      downloads: value,
      uid: "pod-#{podcast_id}-tot-dow"
    })
    |> insert_report()
  end

  def generate({:network, network_id}, :total, :downloads) do
    value = calculate({:network, network_id}, :total, :downloads)

    %Report{}
    |> Report.downloads_changeset(%{
      subject_type: "network",
      subject: network_id,
      time_type: "total",
      downloads: value,
      uid: "net-#{network_id}-tot-dow"
    })
    |> insert_report()
  end

  def generate({:episode, episode_id}, :total, :downloads) do
    value = calculate({:episode, episode_id}, :total, :downloads)

    %Report{}
    |> Report.downloads_changeset(%{
      subject_type: "episode",
      subject: episode_id,
      time_type: "total",
      downloads: value,
      uid: "epi-#{episode_id}-tot-dow"
    })
    |> insert_report()
  end

  def generate({:audio_publication, audio_publication_id}, :total, :downloads) do
    value = calculate({:audio_publication, audio_publication_id}, :total, :downloads)

    %Report{}
    |> Report.downloads_changeset(%{
      subject_type: "audio_publication",
      subject: audio_publication_id,
      time_type: "total",
      downloads: value,
      uid: "aup-#{audio_publication_id}-tot-dow"
    })
    |> insert_report()
  end

  def insert_report(changeset) do
    Repo.insert(changeset,
      on_conflict: :replace_all,
      conflict_target: [:uid]
    )
  end

  def calculate({:podcast, podcast_id}, :total, :downloads) do
    from(d in Download, where: d.podcast_id == ^podcast_id, select: count(d.id))
    |> Repo.one()
  end

  def calculate({:network, network_id}, :total, :downloads) do
    from(d in Download, where: d.network_id == ^network_id, select: count(d.id))
    |> Repo.one()
  end

  def calculate({:episode, episode_id}, :total, :downloads) do
    from(d in Download, where: d.episode_id == ^episode_id, select: count(d.id))
    |> Repo.one()
  end

  def calculate({:audio_publication, audio_publication_id}, :total, :downloads) do
    from(d in Download,
      where: d.audio_publication_id == ^audio_publication_id,
      select: count(d.id)
    )
    |> Repo.one()
  end
end
