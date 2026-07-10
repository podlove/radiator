defmodule RadiatorWeb.Admin.Episodes.ShowLive do
  use RadiatorWeb, :live_view

  import RadiatorWeb.Admin.Episodes.AvailabilityHelpers

  require Logger

  alias Radiator.Podcasts.Episode.Scheduling

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    socket = load_episode_assigns(socket, id)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("vote", %{"proposal-id" => proposal_id, "score" => score_str}, socket) do
    with {score, ""} <- Integer.parse(score_str),
         true <- score in [-1, 0, 1],
         %{} = user <- socket.assigns.current_user,
         %Scheduling{} = scheduling <- socket.assigns.episode.scheduling,
         {:ok, _scheduling} <-
           Scheduling.vote(scheduling, proposal_id, user.id, score,
             actor: socket.assigns.current_user
           ) do
      {:noreply, load_episode_assigns(socket, socket.assigns.episode.id)}
    else
      _ ->
        {:noreply, put_flash(socket, :error, gettext("Could not record your vote."))}
    end
  end

  defp load_episode_assigns(socket, id) do
    episode =
      Radiator.Podcasts.get_episode_by_id!(id,
        load: [:podcast, :scheduling, participants: [:display_name]]
      )

    participants = Enum.sort_by(episode.participants, & &1.display_name)
    participant_ids = Enum.map(participants, & &1.id)

    socket
    |> assign(:episode, episode)
    |> assign(:scheduling_participants, participants)
    |> assign(:participant_ids, participant_ids)
    |> assign(:voting_stats, scheduling_voting_stats(episode.scheduling, participant_ids))
    |> assign(:sorted_proposals, sorted_proposals(episode.scheduling))
  end

  defp scheduling_voting_stats(nil, _participant_ids), do: nil

  defp scheduling_voting_stats(%Scheduling{} = scheduling, participant_ids),
    do: Scheduling.voting_stats(scheduling, participant_ids)

  defp sorted_proposals(nil), do: []

  defp sorted_proposals(%Scheduling{proposals: proposals}) do
    Enum.sort_by(proposals || [], & &1.datetime, DateTime)
  end
end
