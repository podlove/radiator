defmodule Radiator.Reporting.Statistics do
  @moduledoc """
  Access reporting values.
  """

  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Reporting.Report

  alias Radiator.Directory.{
    Network,
    AudioPublication,
    Podcast,
    Episode
  }

  def get_total_downloads(subject = %Network{}), do: do_get_total_downloads("network", subject.id)

  def get_total_downloads(subject = %AudioPublication{}),
    do: do_get_total_downloads("audio_publication", subject.id)

  def get_total_downloads(subject = %Podcast{}), do: do_get_total_downloads("podcast", subject.id)
  def get_total_downloads(subject = %Episode{}), do: do_get_total_downloads("episode", subject.id)

  defp do_get_total_downloads(subject_type, subject_id) when is_binary(subject_type) do
    from(r in Report,
      where:
        r.time_type == "total" and r.subject_type == ^subject_type and r.subject == ^subject_id,
      select: r.downloads
    )
    |> Repo.one()
  end

  def get_monthly_downloads(subject = %Podcast{}, args),
    do: do_get_monthly_downloads("podcast", subject.id, args)

  defp do_get_monthly_downloads(subject_type, subject_id, %{from: from, until: until})
       when is_binary(subject_type) do
    from(r in Report,
      where:
        r.time_type == "month" and r.subject_type == ^subject_type and r.subject == ^subject_id,
      select: %{date: r.time, value: r.downloads},
      order_by: [desc: r.time]
    )
    |> maybe_limit_from_time(from)
    |> maybe_limit_until_time(until)
    |> Repo.all()
  end

  def get_daily_downloads(subject = %Podcast{}, args),
    do: do_get_daily_downloads("podcast", subject.id, args)

  defp do_get_daily_downloads(subject_type, subject_id, %{from: from, until: until})
       when is_binary(subject_type) do
    from(r in Report,
      where:
        r.time_type == "day" and r.subject_type == ^subject_type and r.subject == ^subject_id,
      select: %{date: r.time, value: r.downloads},
      order_by: [desc: r.time]
    )
    |> maybe_limit_from_time(from)
    |> maybe_limit_until_time(until)
    |> Repo.all()
  end

  defp maybe_limit_from_time(query, from_boundary) do
    case from_boundary do
      :unlimited ->
        query

      time ->
        from(r in query, where: r.time >= ^time)
    end
  end

  defp maybe_limit_until_time(query, until_boundary) do
    case until_boundary do
      :unlimited ->
        query

      time ->
        from(r in query, where: r.time <= ^time)
    end
  end
end
