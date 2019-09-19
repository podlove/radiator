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

  def get(args) when is_map(args) do
    query =
      Enum.reduce(args, Report, fn
        {:subject, subject = %Network{}}, query ->
          where(query, subject_type: "network", subject: ^subject.id)

        {:subject, subject = %AudioPublication{}}, query ->
          where(query, subject_type: "audio_publication", subject: ^subject.id)

        {:subject, subject = %Podcast{}}, query ->
          where(query, subject_type: "podcast", subject: ^subject.id)

        {:subject, subject = %Episode{}}, query ->
          where(query, subject_type: "episode", subject: ^subject.id)

        {:time_type, :total}, query ->
          metric = Map.get(args, :metric)

          query
          |> where(time_type: "total")
          |> select([r], map(r, [metric]))

        {:time_type, :month}, query ->
          metric = Map.get(args, :metric)

          query
          |> where(time_type: "month")
          |> select([r], map(r, [metric, :time]))
          |> order_by(desc: :time)

        {:time_type, :day}, query ->
          metric = Map.get(args, :metric)

          query
          |> where(time_type: "day")
          |> select([r], map(r, [metric, :time]))
          |> order_by(desc: :time)

        {:from, from}, query ->
          maybe_limit_from_time(query, from)

        {:until, until}, query ->
          maybe_limit_until_time(query, until)

        _, query ->
          query
      end)

    case Map.get(args, :time_type) do
      :total ->
        Repo.one(query)
        |> format_single_result()

      _ ->
        results =
          query
          |> Repo.all()
          |> List.wrap()

        results =
          case Map.get(args, :metric) do
            :downloads ->
              Enum.map(results, fn %{downloads: value, time: date} ->
                %{date: date, value: value}
              end)

            :listeners ->
              Enum.map(results, fn %{listeners: value, time: date} ->
                %{date: date, value: value}
              end)

            :user_agents ->
              Enum.map(results, fn
                %{downloads: value, time: date} ->
                  %{date: date, value: format_user_agent_data(value)}

                %{listeners: value, time: date} ->
                  %{date: date, value: format_user_agent_data(value)}

                %{user_agents: value, time: date} ->
                  %{date: date, value: format_user_agent_data(value)}
              end)
          end

        results
    end
  end

  def format_single_result(%{user_agents: user_agents}) do
    user_agents |> format_user_agent_data()
  end

  def format_single_result(%{downloads: downloads}) do
    downloads
  end

  def format_single_result(value) do
    value
  end

  def format_user_agent_data(data) when is_map(data) do
    Enum.reduce(data, %{}, fn {key, values}, acc ->
      Map.put(
        acc,
        String.to_existing_atom(key),
        Enum.map(values, fn [percent, absolute, title] ->
          %{
            percent: percent,
            absolute: absolute,
            title: title |> format_title()
          }
        end)
      )
    end)
  end

  def format_user_agent_data(nil) do
    nil
  end

  def format_title(nil), do: "Unknown"
  def format_title(title), do: title

  defp maybe_limit_from_time(query, from_boundary) do
    case from_boundary do
      nil ->
        query

      time ->
        from(r in query, where: r.time >= ^time)
    end
  end

  defp maybe_limit_until_time(query, until_boundary) do
    case until_boundary do
      nil ->
        query

      time ->
        from(r in query, where: r.time <= ^time)
    end
  end
end
