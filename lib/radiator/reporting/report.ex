defmodule Radiator.Reporting.Report do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Tracking.Download

  alias Radiator.Reporting.Report

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
    field :location, :map
    field :user_agents, :map

    timestamps()
  end

  def downloads_changeset(report, attrs) do
    report
    |> cast(attrs, [:uid, :subject_type, :subject, :time_type, :time, :downloads])
    |> validate_required([:uid, :subject_type, :subject, :time_type, :downloads])
  end

  def listeners_changeset(report, attrs) do
    report
    |> cast(attrs, [:uid, :subject_type, :subject, :time_type, :time, :listeners])
    |> validate_required([:uid, :subject_type, :subject, :time_type, :listeners])
  end

  def user_agents_changeset(report, attrs) do
    report
    |> cast(attrs, [:uid, :subject_type, :subject, :time_type, :time, :user_agents])
    |> validate_required([:uid, :subject_type, :subject, :time_type, :user_agents])
  end

  @spec generate(
          {:network | :podcast | :episode | :audio_publication, pos_integer()},
          :total | {:month, Date.t()} | {:day, Date.t()},
          atom()
        ) :: :ok
  def generate(subject, time, metric) do
    value = calculate(subject, time, metric)
    do_generate(subject, time, metric, value)
  end

  ## generate -- handle subject

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

  ## generate -- handle time span

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

  defp do_generate(args, {:day, day}, metric, value) when is_map(args) do
    args
    |> Map.put(:time_type, "day")
    |> Map.put(:time, day |> Date.to_iso8601())
    |> do_generate(metric, value)
  end

  ## generate -- handle metric

  defp do_generate(args, :downloads, value) when is_map(args) do
    args = Map.put(args, :downloads, value)
    args = Map.put(args, :uid, uid(args))

    %Report{}
    |> Report.downloads_changeset(args)
    |> Repo.insert(
      on_conflict: [set: [downloads: value, updated_at: NaiveDateTime.utc_now()]],
      conflict_target: [:uid]
    )

    :ok
  end

  defp do_generate(args, :listeners, value) when is_map(args) do
    args = Map.put(args, :listeners, value)
    args = Map.put(args, :uid, uid(args))

    %Report{}
    |> Report.listeners_changeset(args)
    |> Repo.insert(
      on_conflict: [set: [listeners: value, updated_at: NaiveDateTime.utc_now()]],
      conflict_target: [:uid]
    )

    :ok
  end

  defp do_generate(args, :user_agents, value) when is_map(args) do
    args = Map.put(args, :user_agents, value)
    args = Map.put(args, :uid, uid(args))

    %Report{}
    |> Report.user_agents_changeset(args)
    |> Repo.insert(
      on_conflict: [set: [user_agents: value, updated_at: NaiveDateTime.utc_now()]],
      conflict_target: [:uid]
    )

    :ok
  end

  def uid(args) do
    args
    |> Enum.reduce([], fn
      {:subject_type, "network"}, acc -> ["net#{Map.get(args, :subject)}" | acc]
      {:subject_type, "podcast"}, acc -> ["pod#{Map.get(args, :subject)}" | acc]
      {:subject_type, "episode"}, acc -> ["epi#{Map.get(args, :subject)}" | acc]
      {:subject_type, "audio_publication"}, acc -> ["aup#{Map.get(args, :subject)}" | acc]
      {:time_type, "total"}, acc -> ["t" | acc]
      {:time_type, "month"}, acc -> ["m#{Map.get(args, :time) |> format_month()}" | acc]
      _, acc -> acc
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

  ## calculate -- handle subject

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

  ## calculate -- handle time span

  defp do_calculate(query, :total, metric) do
    do_calculate(query, metric)
  end

  defp do_calculate(query, {:month, date}, metric) do
    do_calculate(for_month(query, date), metric)
  end

  defp do_calculate(_query, {:day, _}, :user_agents) do
    # I'd say user agents on a daily basis, no matter what subject, are pointless.
    # So unless we decide otherwise I'm going to explicitly forbid it by raising
    # because if we end up accidentally generating it, it will use up big
    # chunks of data (~1kb per day per episode?)
    raise "calculation of user agents per day is not allowed"
  end

  defp do_calculate(query, {:day, date}, metric) do
    do_calculate(for_day(query, date), metric)
  end

  ## calculate -- handle metric

  defp do_calculate(query, :downloads) do
    from(d in query, select: count(d.id)) |> Repo.one()
  end

  defp do_calculate(query, :listeners) do
    subquery = from(d in query, group_by: :request_id, select: d.request_id)
    from(x in subquery(subquery), select: count(x.request_id)) |> Repo.one()
  end

  @user_agent_limit 20
  defp do_calculate(query, :user_agents) do
    total = do_calculate(query, :downloads)

    prepend_percentage = fn list ->
      Enum.map(list, fn data = [count | _] -> [Float.round(100 * count / total, 2) | data] end)
    end

    client_name =
      from(d in query,
        group_by: d.client_name,
        order_by: [desc: 1],
        limit: @user_agent_limit,
        select: [count(d.id), d.client_name]
      )
      |> Repo.all()
      |> prepend_percentage.()

    client_type =
      from(d in query,
        group_by: d.client_type,
        order_by: [desc: 1],
        limit: @user_agent_limit,
        select: [count(d.id), d.client_type]
      )
      |> Repo.all()
      |> prepend_percentage.()

    os_name =
      from(d in query,
        group_by: d.os_name,
        order_by: [desc: 1],
        limit: @user_agent_limit,
        select: [count(d.id), d.os_name]
      )
      |> Repo.all()
      |> prepend_percentage.()

    device_type =
      from(d in query,
        group_by: d.device_type,
        order_by: [desc: 1],
        limit: @user_agent_limit,
        select: [count(d.id), d.device_type]
      )
      |> Repo.all()
      |> prepend_percentage.()

    %{
      client_name: client_name,
      client_type: client_type,
      os_name: os_name,
      device_type: device_type
    }
  end

  def for_month(query, date = %Date{}) do
    time = NaiveDateTime.from_iso8601!("#{Date.to_iso8601(date)}T00:00:00.000Z")
    beginning_of_month = Timex.beginning_of_month(time)
    end_of_month = beginning_of_month |> Timex.end_of_month()

    from(d in query,
      where: d.accessed_at >= ^beginning_of_month and d.accessed_at <= ^end_of_month
    )
  end

  def for_day(query, date = %Date{}) do
    time = NaiveDateTime.from_iso8601!("#{Date.to_iso8601(date)}T00:00:00.000Z")
    beginning_of_day = Timex.beginning_of_day(time)
    end_of_day = beginning_of_day |> Timex.end_of_day()

    from(d in query,
      where: d.accessed_at >= ^beginning_of_day and d.accessed_at <= ^end_of_day
    )
  end
end
