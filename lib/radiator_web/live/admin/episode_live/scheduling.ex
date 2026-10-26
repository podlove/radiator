defmodule RadiatorWeb.Admin.EpisodeLive.Scheduling do
  @moduledoc """
  The search for an episode's recording date (ADR 0001 §4).

  Open to the podcast's members and to the episode's contributors: members
  start the search, pick the date and reopen; contributors with an account
  vote and propose dates. The contributor invitation mail links here, which
  is why the podcast is read through its public action — contributors are
  usually not members of it.

  Dates are shown and read in the browser's time zone (connect param
  `timezone`).
  """

  use RadiatorWeb, :live_view

  import RadiatorWeb.Admin.EpisodeLive.SchedulingHelpers

  require Ash.Query

  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.Episode.Scheduling.Access
  alias Radiator.Podcasts.Episode.Scheduling.Stats
  alias Radiator.Podcasts.Episode.Scheduling.Voter

  @impl true
  def mount(%{"podcast_id" => podcast_id, "id" => id}, _session, socket) do
    actor = socket.assigns.current_user

    with {:ok, podcast} <- Podcasts.public_get_podcast_by_id(podcast_id),
         {:ok, episode} <- get_episode(podcast.id, id),
         member? = Access.member?(podcast.id, actor),
         true <- member? or Access.contributor?(episode.id, actor) do
      socket
      |> assign(podcast: podcast, episode: episode, member?: member?)
      |> assign(:page_title, gettext("Terminfindung"))
      |> assign(:timezone, timezone(connect_timezone(socket)))
      |> assign(:proposal_form, proposal_form())
      |> assign_scheduling()
      |> ok()
    else
      _no_access ->
        socket
        |> put_flash(
          :error,
          gettext("Diese Terminfindung gibt es nicht oder sie ist nicht für dich.")
        )
        |> push_navigate(to: ~p"/admin")
        |> ok()
    end
  end

  defp get_episode(podcast_id, id) do
    Episode
    |> Ash.Query.filter(id == ^id and podcast_id == ^podcast_id)
    |> Ash.read_one(not_found_error?: true)
  end

  defp connect_timezone(socket) do
    if connected?(socket), do: get_connect_params(socket)["timezone"]
  end

  defp proposal_form, do: to_form(%{"datetime" => ""}, as: :proposal)

  # Everything on the page follows from the scheduling, so every change
  # re-reads it rather than patching assigns.
  defp assign_scheduling(socket) do
    %{episode: episode, current_user: actor} = socket.assigns

    scheduling =
      case Podcasts.get_scheduling_by_episode(episode.id, actor: actor) do
        {:ok, scheduling} -> scheduling
        {:error, _none} -> nil
      end

    participants = Podcasts.read_scheduling_participants!(episode.id)

    current_person_id =
      case Voter.person_id(episode.id, actor) do
        {:ok, person_id} -> person_id
        :error -> nil
      end

    stats = scheduling && Stats.voting_stats(scheduling, Enum.map(participants, & &1.id))

    assign(socket,
      scheduling: scheduling,
      participants: participants,
      current_person_id: current_person_id,
      stats: stats,
      winner_id: Stats.winner_proposal_id(scheduling, stats && stats.top_proposal_id)
    )
  end

  @impl true
  def handle_event("start", %{"proposal" => %{"datetime" => value}}, socket) do
    %{episode: episode, timezone: timezone, current_user: actor} = socket.assigns

    with {:ok, datetime} <- parse_local(value, timezone),
         {:ok, _scheduling} <- Podcasts.start_scheduling(episode.id, [datetime], actor: actor) do
      socket
      |> put_flash(:info, gettext("Terminfindung gestartet."))
      |> assign(:proposal_form, proposal_form())
      |> assign_scheduling()
      |> noreply()
    else
      _error ->
        socket |> put_flash(:error, gettext("Bitte gib einen gültigen Termin an.")) |> noreply()
    end
  end

  def handle_event("add_proposal", %{"proposal" => %{"datetime" => value}}, socket) do
    with {:ok, datetime} <- parse_local(value, socket.assigns.timezone),
         {:ok, _scheduling} <-
           Podcasts.add_scheduling_proposal(socket.assigns.scheduling, datetime,
             actor: socket.assigns.current_user
           ) do
      socket
      |> assign(:proposal_form, proposal_form())
      |> assign_scheduling()
      |> noreply()
    else
      _error ->
        socket
        |> put_flash(:error, gettext("Der Termin konnte nicht vorgeschlagen werden."))
        |> assign_scheduling()
        |> noreply()
    end
  end

  def handle_event("remove_proposal", %{"proposal-id" => proposal_id}, socket) do
    socket.assigns.scheduling
    |> Podcasts.remove_scheduling_proposal(proposal_id, actor: socket.assigns.current_user)
    |> after_change(socket, gettext("Der Termin konnte nicht entfernt werden."))
  end

  def handle_event("vote", %{"proposal-id" => proposal_id, "score" => score}, socket) do
    case Integer.parse(score) do
      {score, ""} when score in [-1, 0, 1] ->
        socket.assigns.scheduling
        |> Podcasts.vote_on_proposal(proposal_id, score, actor: socket.assigns.current_user)
        |> after_change(socket, gettext("Deine Stimme konnte nicht gespeichert werden."))

      _invalid ->
        socket
        |> put_flash(:error, gettext("Deine Stimme konnte nicht gespeichert werden."))
        |> noreply()
    end
  end

  def handle_event("finalize", %{"proposal-id" => proposal_id}, socket) do
    socket.assigns.scheduling
    |> Podcasts.finalize_scheduling(proposal_id, actor: socket.assigns.current_user)
    |> after_change(socket, gettext("Der Termin konnte nicht festgelegt werden."))
  end

  def handle_event("reopen", _params, socket) do
    socket.assigns.scheduling
    |> Podcasts.reopen_scheduling(actor: socket.assigns.current_user)
    |> after_change(socket, gettext("Die Terminfindung konnte nicht wieder geöffnet werden."))
  end

  defp after_change({:ok, _scheduling}, socket, _message),
    do: socket |> assign_scheduling() |> noreply()

  defp after_change({:error, _error}, socket, message),
    do: socket |> put_flash(:error, message) |> assign_scheduling() |> noreply()

  defp vote_buttons(assigns) do
    ~H"""
    <div class="flex justify-center gap-1">
      <button
        :for={{target, name, icon, label} <- vote_targets()}
        id={"vote-#{@proposal.id}-#{name}"}
        type="button"
        class={["btn btn-sm btn-square", vote_button_class(@score, target)]}
        phx-click="vote"
        phx-value-proposal-id={@proposal.id}
        phx-value-score={target}
        disabled={@disabled}
        aria-label={label}
        aria-pressed={to_string(@score == target)}
      >
        <.icon name={icon} class="size-4" />
      </button>
    </div>
    """
  end

  defp vote_targets do
    [
      {1, "yes", "hero-check", gettext("Ja")},
      {0, "maybe", "hero-question-mark-circle", gettext("Vielleicht")},
      {-1, "no", "hero-x-mark", gettext("Nein")}
    ]
  end

  defp vote_icon(assigns) do
    ~H"""
    <span :if={is_nil(@score)} class="text-base-content/30">–</span>
    <.icon :if={@score == 1} name="hero-check" class="size-5 text-success" />
    <.icon :if={@score == 0} name="hero-question-mark-circle" class="size-5 text-warning" />
    <.icon :if={@score == -1} name="hero-x-mark" class="size-5 text-error" />
    """
  end
end
