defmodule RadiatorWeb.Admin.Episodes.ShowLive do
  use RadiatorWeb, :live_view

  import RadiatorWeb.Admin.Episodes.AvailabilityHelpers

  require Ash.Query
  require Logger

  alias Radiator.People.Persona
  alias Radiator.Podcasts.Episode.Scheduling

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    current_user = socket.assigns.current_user
    current_persona = lookup_current_persona(current_user)

    socket =
      socket
      |> assign(:current_persona, current_persona)
      |> load_episode_assigns(id)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("vote", %{"proposal-id" => proposal_id, "score" => score_str}, socket) do
    with {score, ""} <- Integer.parse(score_str),
         true <- score in [-1, 0, 1],
         %{} = persona <- socket.assigns.current_persona,
         %Scheduling{} = scheduling <- socket.assigns.episode.scheduling,
         {:ok, _scheduling} <-
           Scheduling.vote(scheduling, proposal_id, persona.id, score,
             actor: socket.assigns.current_user
           ) do
      {:noreply, load_episode_assigns(socket, socket.assigns.episode.id)}
    else
      _ ->
        {:noreply, put_flash(socket, :error, gettext("Could not record your vote."))}
    end
  end

  defp lookup_current_persona(nil), do: nil

  defp lookup_current_persona(%{id: user_id}) do
    case Persona.get_by_user(user_id) do
      {:ok, persona} -> persona
      {:error, _} -> nil
    end
  end

  defp load_episode_assigns(socket, id) do
    episode =
      Radiator.Podcasts.get_episode_by_id!(id, load: [:podcast, :participants, :scheduling])

    socket
    |> assign(:episode, episode)
    |> assign(:scheduling_participants, load_scheduling_participants(episode.scheduling))
    |> assign(:voting_stats, scheduling_voting_stats(episode.scheduling))
    |> assign(:sorted_proposals, sorted_proposals(episode.scheduling))
  end

  defp load_scheduling_participants(nil), do: []

  defp load_scheduling_participants(%Scheduling{participant_persona_ids: ids})
       when ids in [nil, []],
       do: []

  defp load_scheduling_participants(%Scheduling{participant_persona_ids: ids}) do
    Persona
    |> Ash.Query.filter(id in ^ids)
    |> Ash.read!(authorize?: false)
    |> Enum.sort_by(& &1.public_name)
  end

  defp scheduling_voting_stats(nil), do: nil

  defp scheduling_voting_stats(%Scheduling{} = scheduling),
    do: Scheduling.voting_stats(scheduling)

  defp sorted_proposals(nil), do: []

  defp sorted_proposals(%Scheduling{proposals: proposals}) do
    Enum.sort_by(proposals || [], & &1.datetime, DateTime)
  end
end
