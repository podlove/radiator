defmodule Radiator.Reporting.Report do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Tracking.Download

  alias Radiator.Reporting.{
    Report,
    ReportWorker
  }

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
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :total,
        metric: :downloads
      })
    end)
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
      # FIXME: I probably don't want :replace_all here but only the currently updated value?
      #        Needs testing. Then maybe I need a custom Repo.insert in every `generate`.
      on_conflict: :replace_all,
      conflict_target: [:uid]
    )
  end

  def calculate({:podcast, podcast_id}, time, metric) do
    from(d in Download, where: d.podcast_id == ^podcast_id)
    |> do_calculate(time, metric)
  end

  def calculate({:network, network_id}, time, metric) do
    from(d in Download, where: d.network_id == ^network_id)
    |> do_calculate(time, metric)
  end

  def calculate({:episode, episode_id}, time, metric) do
    from(d in Download, where: d.episode_id == ^episode_id)
    |> do_calculate(time, metric)
  end

  def calculate({:audio_publication, audio_publication_id}, time, metric) do
    from(d in Download, where: d.audio_publication_id == ^audio_publication_id)
    |> do_calculate(time, metric)
  end

  defp do_calculate(query, :total, metric) do
    do_calculate(query, metric)
  end

  defp do_calculate(query, {:month, date}, metric) do
    do_calculate(for_month(query, date), metric)
  end

  defp do_calculate(query, :downloads) do
    from(d in query, select: count(d.id)) |> Repo.one()
  end

  defp do_calculate(query, :listeners) do
    subquery = from(d in query, group_by: :request_id, select: d.request_id)
    from(x in subquery(subquery), select: count(x.request_id)) |> Repo.one()
  end

  def for_month(query, date = %Date{}) do
    time = NaiveDateTime.from_iso8601!("#{Date.to_iso8601(date)}T00:00:00.000Z")
    beginning_of_month = Timex.beginning_of_month(time)
    end_of_month = beginning_of_month |> Timex.end_of_month()

    from(d in query,
      where: d.accessed_at >= ^beginning_of_month and d.accessed_at <= ^end_of_month
    )
  end
end
