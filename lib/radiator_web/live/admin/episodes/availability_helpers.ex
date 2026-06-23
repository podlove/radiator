defmodule RadiatorWeb.Admin.Episodes.AvailabilityHelpers do
  @moduledoc """
  Pure helper functions used by the read-only availability matrix on the
  episode show page (`RadiatorWeb.Admin.Episodes.ShowLive`).

  All helpers are side-effect free and safe to call from HEEx templates.
  """

  alias Radiator.Podcasts.Episode.Scheduling

  # German weekday short labels keyed by `Date.day_of_week/1` (1 = Monday,
  # 7 = Sunday). v1 only renders German labels; localisation via Gettext is
  # explicitly out of scope for issue 03 (see spec §5.3).
  @weekday_labels %{
    1 => "Mo",
    2 => "Di",
    3 => "Mi",
    4 => "Do",
    5 => "Fr",
    6 => "Sa",
    7 => "So"
  }

  @doc """
  Returns true when the given user is among the episode's participants
  (the eligible voters), identified by `participant_ids`.

  Accepts `nil` for the user and treats it as "not a participant" so the
  helper can be used directly in templates without extra nil-guards.
  """
  def participant?(_participant_ids, nil), do: false

  def participant?(participant_ids, %{id: user_id}) do
    user_id in (participant_ids || [])
  end

  @doc """
  Find a single user's vote for a given proposal.

  Returns the matching vote struct or `nil` if the user has not voted
  on this proposal yet.
  """
  def vote_for_user(proposal, user_id) when is_binary(user_id) do
    Enum.find(proposal.votes || [], &(&1.user_id == user_id))
  end

  @doc """
  Returns true if the given `DateTime` falls on Saturday or Sunday.
  """
  def weekend?(%DateTime{} = datetime) do
    Date.day_of_week(datetime) in [6, 7]
  end

  @doc """
  Returns the German short label for the weekday of `datetime`
  (e.g. `"Mo"`, `"Di"`, ..., `"So"`).
  """
  def weekday_label(%DateTime{} = datetime) do
    Map.fetch!(@weekday_labels, Date.day_of_week(datetime))
  end

  @doc """
  Format a total score with an explicit sign for non-zero values.

  ## Examples

      iex> format_total_score(2)
      "+2"

      iex> format_total_score(0)
      "0"

      iex> format_total_score(-1)
      "-1"
  """
  def format_total_score(score) when is_integer(score) and score > 0, do: "+#{score}"
  def format_total_score(score) when is_integer(score), do: Integer.to_string(score)

  @doc """
  Look up the `total_score` for a given proposal id from a `voting_stats` map.

  Returns `0` when the proposal id is unknown or `voting_stats` is `nil`,
  which keeps the template rendering robust against missing data.
  """
  def proposal_total_score(nil, _proposal_id), do: 0

  def proposal_total_score(%{proposal_stats: stats}, proposal_id) do
    case Enum.find(stats, &(&1.proposal_id == proposal_id)) do
      nil -> 0
      stat -> stat.total_score
    end
  end

  @doc """
  Return the DaisyUI button class for a voting button.

  `current_vote` is either `nil` (no vote yet) or a `Vote` struct with a `:score`
  field. `target_score` is the score the button represents (`1`, `0`, or `-1`).

  When `current_vote.score` matches `target_score`, returns the colored
  highlight class (`btn-success`/`btn-warning`/`btn-error`). Otherwise the
  neutral `btn-ghost` class.
  """
  def vote_button_class(%{score: score}, target_score) when score == target_score do
    case target_score do
      1 -> "btn-success"
      0 -> "btn-warning"
      -1 -> "btn-error"
    end
  end

  def vote_button_class(_current_vote, _target_score), do: "btn-ghost"

  @doc """
  Returns true when the given user is allowed to cast a vote on the
  given scheduling right now.

  All of the following must hold:

    * `scheduling` is not `nil`
    * `user` is not `nil`
    * `scheduling.status == :open`
    * `user` is among `participant_ids` (the episode's participants)
      (via `participant?/2`)

  Used in the LiveView template to bind the `disabled` attribute of the
  three voting buttons.
  """
  def can_vote?(nil, _user, _participant_ids), do: false
  def can_vote?(_scheduling, nil, _participant_ids), do: false

  def can_vote?(%Scheduling{status: :open}, user, participant_ids),
    do: participant?(participant_ids, user)

  def can_vote?(%Scheduling{}, _user, _participant_ids), do: false

  @doc """
  Single source of truth for "which proposal gets the winner highlight?".

  When `scheduling.status == :closed` and `scheduling.chosen_proposal_id`
  is set, the owner's explicit choice wins over the automatically
  calculated `top_proposal_id`. Otherwise the automatically calculated
  `top_proposal_id` (which may itself be `nil` on a tie) is returned.

  Returns `nil` when `scheduling` is `nil`, or when the scheduling is
  closed without a chosen proposal (edge case: reopen with reset).
  """
  def winner_proposal_id(nil, _top_proposal_id), do: nil

  def winner_proposal_id(%Scheduling{status: :closed, chosen_proposal_id: nil}, _top), do: nil

  def winner_proposal_id(%Scheduling{status: :closed, chosen_proposal_id: chosen_id}, _top),
    do: chosen_id

  def winner_proposal_id(%Scheduling{}, top_proposal_id), do: top_proposal_id
end
