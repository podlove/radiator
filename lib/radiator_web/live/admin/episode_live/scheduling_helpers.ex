defmodule RadiatorWeb.Admin.EpisodeLive.SchedulingHelpers do
  @moduledoc """
  Side-effect free helpers for the scheduling page: time zones, labels and
  the state of the vote buttons. Safe to call from templates.
  """

  use Gettext, backend: RadiatorWeb.Gettext

  alias Radiator.Podcasts.Episode.Scheduling.Proposal

  @default_timezone "Europe/Berlin"

  @doc "The time zone to show and read dates in; the browser's if it is a known one."
  def timezone(name) when is_binary(name) do
    case DateTime.now(name) do
      {:ok, _now} -> name
      {:error, _unknown} -> @default_timezone
    end
  end

  def timezone(_name), do: @default_timezone

  @doc "`datetime` (UTC) as seen in `timezone`."
  def local(%DateTime{} = datetime, timezone), do: DateTime.shift_zone!(datetime, timezone)

  @doc """
  Reads the value of a `datetime-local` input (`"2026-11-06T19:00"`) as a
  time in `timezone` and returns it in UTC. A time skipped by a daylight
  saving switch is moved past the gap; a time that exists twice is the
  first of the two.
  """
  def parse_local(value, timezone) when is_binary(value) do
    with {:ok, naive} <- value |> with_seconds() |> NaiveDateTime.from_iso8601(),
         {:ok, datetime} <- from_naive(naive, timezone) do
      {:ok, DateTime.shift_zone!(datetime, "Etc/UTC")}
    else
      _invalid -> :error
    end
  end

  def parse_local(_value, _timezone), do: :error

  defp with_seconds(value) when byte_size(value) == 16, do: value <> ":00"
  defp with_seconds(value), do: value

  defp from_naive(naive, timezone) do
    case DateTime.from_naive(naive, timezone) do
      {:ok, datetime} -> {:ok, datetime}
      {:ambiguous, first, _second} -> {:ok, first}
      {:gap, _before, just_after} -> {:ok, just_after}
      error -> error
    end
  end

  @doc "Short weekday name, e.g. `Mo`."
  def weekday_label(%DateTime{} = datetime) do
    case Date.day_of_week(datetime) do
      1 -> gettext("Mo")
      2 -> gettext("Di")
      3 -> gettext("Mi")
      4 -> gettext("Do")
      5 -> gettext("Fr")
      6 -> gettext("Sa")
      7 -> gettext("So")
    end
  end

  def weekend?(%DateTime{} = datetime), do: Date.day_of_week(datetime) in [6, 7]

  def date(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%d.%m.%Y")
  def time(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%H:%M")

  @doc "A total score with its sign: `+2`, `0`, `-1`."
  def format_score(score) when score > 0, do: "+#{score}"
  def format_score(score), do: Integer.to_string(score)

  @doc "The stats entry of `proposal_id`, or `nil`."
  def proposal_stat(%{proposal_stats: stats}, proposal_id),
    do: Enum.find(stats, &(&1.proposal_id == proposal_id))

  def proposal_stat(_stats, _proposal_id), do: nil

  @doc "The score `person_id` gave the proposal, or `nil` while pending."
  def score(%Proposal{} = proposal, person_id) do
    case Proposal.vote_by_person(proposal, person_id) do
      nil -> nil
      vote -> vote.score
    end
  end

  @doc "Button class for the vote button of `target` when the current score is `score`."
  def vote_button_class(score, score), do: active_vote_class(score)
  def vote_button_class(_score, _target), do: "btn-ghost"

  defp active_vote_class(1), do: "btn-success"
  defp active_vote_class(0), do: "btn-warning"
  defp active_vote_class(-1), do: "btn-error"

  @doc "Whether the current user can vote right now."
  def can_vote?(%{status: :open}, person_id) when is_binary(person_id), do: true
  def can_vote?(_scheduling, _person_id), do: false

  @doc "Whether `user` may remove the proposal: its creator, or any member."
  def can_remove?(%{status: :open}, _proposal, _user, true = _member?), do: true

  def can_remove?(%{status: :open}, %Proposal{created_by_user_id: id}, %{id: id}, _member?),
    do: true

  def can_remove?(_scheduling, _proposal, _user, _member?), do: false

  @doc "Proposals in calendar order."
  def chronological(proposals), do: Enum.sort_by(proposals || [], & &1.datetime, DateTime)
end
