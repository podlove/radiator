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

  def handle_event("finalize", %{"proposal-id" => proposal_id}, socket) do
    %{current_user: user, episode: episode} = socket.assigns

    with %Scheduling{} = scheduling <- episode.scheduling,
         {:ok, _scheduling} <- Scheduling.finalize(scheduling, proposal_id, user.id, actor: user) do
      socket = load_episode_assigns(socket, episode.id)
      {:noreply, notify_and_flash(socket)}
    else
      _ -> {:noreply, put_flash(socket, :error, gettext("Could not close the voting."))}
    end
  end

  def handle_event("reopen", _params, socket) do
    %{current_user: user, episode: episode} = socket.assigns

    with %Scheduling{} = scheduling <- episode.scheduling,
         {:ok, _scheduling} <- Scheduling.reopen(scheduling, user.id, actor: user) do
      socket =
        socket
        |> load_episode_assigns(episode.id)
        |> put_flash(:info, gettext("Voting reopened."))

      {:noreply, socket}
    else
      _ -> {:noreply, put_flash(socket, :error, gettext("Could not reopen the voting."))}
    end
  end

  defp notify_and_flash(socket) do
    {:ok, participants} = Radiator.Podcasts.notify_participants_of_result(socket.assigns.episode)

    put_flash(
      socket,
      :info,
      gettext("Voting closed, %{count} participant(s) notified", count: length(participants))
    )
  rescue
    error ->
      Logger.error("Failed to notify participants of voting result: #{inspect(error)}")

      socket
      |> put_flash(:info, gettext("Voting closed."))
      |> put_flash(:error, gettext("Participants could not be notified."))
  end

  defp load_episode_assigns(socket, id) do
    episode =
      Radiator.Podcasts.get_episode_by_id!(id,
        load: [:podcast, :scheduling, participants: [:display_name]]
      )

    participants = Enum.sort_by(episode.participants, & &1.display_name)
    participant_ids = Enum.map(participants, & &1.id)
    voting_stats = scheduling_voting_stats(episode.scheduling, participant_ids)
    sorted_proposals = sorted_proposals(episode.scheduling)

    socket
    |> assign(:episode, episode)
    |> assign(:scheduling_participants, participants)
    |> assign(:participant_ids, participant_ids)
    |> assign(:voting_stats, voting_stats)
    |> assign(:sorted_proposals, sorted_proposals)
    |> assign(:default_finalize_id, default_finalize_id(voting_stats, sorted_proposals))
  end

  defp scheduling_voting_stats(nil, _participant_ids), do: nil

  defp scheduling_voting_stats(%Scheduling{} = scheduling, participant_ids),
    do: Scheduling.voting_stats(scheduling, participant_ids)

  defp sorted_proposals(nil), do: []

  defp sorted_proposals(%Scheduling{proposals: proposals}) do
    Enum.sort_by(proposals || [], & &1.datetime, DateTime)
  end

  defp default_finalize_id(nil, _sorted_proposals), do: nil

  defp default_finalize_id(%{top_proposal_id: top_proposal_id}, sorted_proposals),
    do: top_proposal_id || first_proposal_id(sorted_proposals)

  defp first_proposal_id([%{id: id} | _]), do: id
  defp first_proposal_id(_), do: nil
end
