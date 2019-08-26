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
    fetch_entities()
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :total,
        metric: :downloads
      })
    end)
  end

  @doc """
  Generate all monthly dowanloads for given month.

  For:
    - all Networks
    - all Podcasts
    - all Episodes
    - all AudioPublications

  TODO(perf): only fetch entities published on or after given month
  """
  def generate_all_monthly_downloads(month = %Date{}) do
    fetch_entities()
    |> Enum.each(fn {subject_type, subject} ->
      ReportWorker.enqueue(%{
        subject_type: subject_type,
        subject: subject,
        time_type: :month,
        time: month,
        metric: :downloads
      })
    end)
  end

  defp fetch_entities do
    [
      Repo.all(Network) |> Enum.map(&{:network, &1.id}),
      Repo.all(Podcast) |> Enum.map(&{:podcast, &1.id}),
      Repo.all(Episode) |> Enum.map(&{:episode, &1.id}),
      Repo.all(AudioPublication) |> Enum.map(&{:audio_publication, &1.id})
    ]
    |> List.flatten()
  end

  @spec generate(
          {:network | :podcast | :episode | :audio_publication, pos_integer()},
          :total | {:month, any()},
          atom()
        ) :: :ok
  def generate(subject, time, metric) do
    value = calculate(subject, time, metric)
    do_generate(subject, time, metric, value)
  end

  defp do_generate({:network, network_id}, time, metric, value) do
    %{
      subject_type: "network",
      subject: network_id
    }
    |> do_generate(time, metric, value)
  end

  defp do_generate({:podcast, podcast_id}, time, metric, value) do
    %{
      subject_type: "podcast",
      subject: podcast_id
    }
    |> do_generate(time, metric, value)
  end

  defp do_generate({:episode, episode_id}, time, metric, value) do
    %{
      subject_type: "episode",
      subject: episode_id
    }
    |> do_generate(time, metric, value)
  end

  defp do_generate({:audio_publication, audio_publication_id}, time, metric, value) do
    %{
      subject_type: "audio_publication",
      subject: audio_publication_id
    }
    |> do_generate(time, metric, value)
  end

  defp do_generate(args, :total, metric, value) when is_map(args) do
    args
    |> Map.put(:time_type, "total")
    |> do_generate(metric, value)
  end

  defp do_generate(args, {:month, month}, metric, value) when is_map(args) do
    args
    |> Map.put(:time_type, "month")
    |> Map.put(:time, month |> Date.to_iso8601() |> format_month())
    |> do_generate(metric, value)
  end

  defp do_generate(args, :downloads, value) when is_map(args) do
    args = Map.put(args, :downloads, value)
    args = Map.put(args, :uid, uid(args, :downloads))

    # todo: only insert if value > 0?
    %Report{}
    |> Report.downloads_changeset(args)
    |> insert_report()

    :ok
  end

  def uid(args, :downloads) do
    args
    |> Enum.reduce([], fn
      {:subject_type, "network"}, acc -> ["net#{Map.get(args, :subject)}" | acc]
      {:subject_type, "podcast"}, acc -> ["pod#{Map.get(args, :subject)}" | acc]
      {:subject_type, "episode"}, acc -> ["epi#{Map.get(args, :subject)}" | acc]
      {:subject_type, "audio_publication"}, acc -> ["aup#{Map.get(args, :subject)}" | acc]
      {:subject, _}, acc -> acc
      {:time_type, "total"}, acc -> ["t" | acc]
      {:time_type, "month"}, acc -> ["m#{Map.get(args, :time) |> format_month()}" | acc]
      {:time, _}, acc -> acc
      {:downloads, _}, acc -> ["dow" | acc]
    end)
    |> Enum.reverse()
    |> Enum.join("-")
  end

  defp format_month(date) when is_binary(date) do
    date |> String.split("-") |> Enum.take(2) |> Enum.join("-")
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
