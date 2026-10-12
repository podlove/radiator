defmodule RadiatorWeb.Admin.EpisodeLive.Form do
  use RadiatorWeb, :live_view

  require Ash.Query

  alias AshPhoenix.Form
  alias Radiator.Podcasts
  alias Radiator.Podcasts.Episode
  alias Radiator.Podcasts.EpisodeContributor
  alias Radiator.Podcasts.EpisodeType
  alias Radiator.Podcasts.Podcast
  alias RadiatorWeb.Formatting

  @impl true
  def mount(%{"podcast_id" => podcast_id} = params, _session, socket) do
    actor = socket.assigns.current_user
    podcast = Ash.get!(Podcast, podcast_id, load: [:display_title], actor: actor)
    episode = load_episode(podcast, params["id"], actor)

    socket
    |> assign(podcast: podcast, episode: episode)
    |> assign(:contributor_persons, Podcasts.read_podcast_contributors!(podcast.id))
    |> assign(:suggest, nil)
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign(form: build_form(podcast, episode, actor))
    |> ok()
  end

  defp load_episode(_podcast, nil, _actor), do: nil

  defp load_episode(podcast, id, actor) do
    Episode
    |> Ash.Query.filter(id == ^id and podcast_id == ^podcast.id)
    |> Ash.Query.load(contributors: Ash.Query.sort(EpisodeContributor, :inserted_at))
    |> Ash.read_one!(actor: actor, not_found_error?: true)
  end

  defp page_title(:edit), do: gettext("Episode bearbeiten")
  defp page_title(_live_action), do: gettext("Neue Episode")

  # The podcast comes from the route, not from the form.
  defp build_form(podcast, nil, actor) do
    Episode
    |> Form.for_create(:create,
      as: "episode",
      actor: actor,
      transform_params: fn _form, params, _type -> Map.put(params, "podcast_id", podcast.id) end
    )
    |> to_form()
  end

  defp build_form(_podcast, episode, actor) do
    episode |> Form.for_update(:update, as: "episode", actor: actor) |> to_form()
  end

  @impl true
  def handle_event("validate", %{"episode" => params} = event, socket) do
    socket
    |> assign(form: Form.validate(socket.assigns.form, params))
    |> assign(suggest: suggest_target(event))
    |> noreply()
  end

  def handle_event("add-form", %{"path" => path}, socket) do
    socket |> assign(form: Form.add_form(socket.assigns.form, path)) |> noreply()
  end

  def handle_event("remove-form", %{"path" => path}, socket) do
    socket |> assign(form: Form.remove_form(socket.assigns.form, path)) |> noreply()
  end

  def handle_event("pick-contributor", %{"path" => path, "person-id" => person_id}, socket) do
    socket
    |> assign(form: Form.update_form(socket.assigns.form, path, &put_person(&1, person_id)))
    |> assign(suggest: nil)
    |> noreply()
  end

  def handle_event("clear-contributor", %{"path" => path}, socket) do
    socket
    |> assign(form: Form.update_form(socket.assigns.form, path, &put_person(&1, nil)))
    |> noreply()
  end

  def handle_event("save", %{"episode" => params}, socket) do
    case Form.submit(socket.assigns.form, params: params) do
      {:ok, _episode} ->
        socket
        |> put_flash(:info, saved_message(socket.assigns.live_action))
        |> push_navigate(to: ~p"/admin/podcasts/#{socket.assigns.podcast}")
        |> noreply()

      {:error, form} ->
        socket |> assign(form: form) |> noreply()
    end
  end

  defp saved_message(:edit), do: gettext("Episode gespeichert.")
  defp saved_message(_live_action), do: gettext("Episode angelegt.")

  @suggestion_limit 8

  # Only the row whose text was just typed into shows suggestions.
  defp suggest_target(%{
         "_target" => ["episode", "contributors", index, "email"],
         "episode" => params
       }) do
    %{
      path: "episode[contributors][#{index}]",
      query: get_in(params, ["contributors", index, "email"]) || ""
    }
  end

  defp suggest_target(_event), do: nil

  defp put_person(contributor, nil),
    do: Form.validate(contributor, Map.drop(contributor.params, ["person_id"]))

  defp put_person(contributor, person_id) do
    params = contributor.params |> Map.drop(["email"]) |> Map.put("person_id", person_id)
    Form.validate(contributor, params)
  end

  defp taken_person_ids(form) do
    form.source.forms
    |> Map.get(:contributors, [])
    |> Enum.map(&Form.value(&1, :person_id))
  end

  defp suggestions(persons, %{path: path, query: query}, path, taken) do
    case query |> String.trim() |> String.downcase() do
      "" ->
        []

      needle ->
        persons
        |> Enum.filter(&String.contains?(String.downcase(&1.name), needle))
        |> Enum.reject(&(&1.id in taken))
        |> Enum.take(@suggestion_limit)
    end
  end

  defp suggestions(_persons, _suggest, _path, _taken), do: []

  defp selected_person(persons, person_id), do: Enum.find(persons, &(&1.id == person_id))

  defp contributor_picker(assigns) do
    assigns =
      assign(assigns,
        selected: selected_person(assigns.persons, assigns.contributor[:person_id].value),
        suggestions:
          suggestions(assigns.persons, assigns.suggest, assigns.contributor.name, assigns.taken)
      )

    ~H"""
    <div class="fieldset mb-2">
      <span class="label mb-1">{gettext("Person")}</span>
      <div :if={@selected} class="flex h-10 items-center gap-2">
        <input type="hidden" name={@contributor[:person_id].name} value={@selected.id} />
        <span class="badge badge-lg badge-soft badge-primary gap-1">
          <.icon name="hero-user" class="size-4" /> {@selected.name}
        </span>
        <button
          :if={@contributor.source.type == :create}
          type="button"
          class="btn btn-ghost btn-xs btn-circle"
          phx-click="clear-contributor"
          phx-value-path={@contributor.name}
          aria-label={gettext("Andere Person wählen")}
        >
          <.icon name="hero-arrow-path" class="size-3" />
        </button>
      </div>
      <div :if={!@selected} class="relative">
        <.input
          field={@contributor[:email]}
          type="text"
          placeholder={gettext("Name suchen oder E-Mail eingeben")}
          autocomplete="off"
          phx-debounce="200"
        />
        <ul
          :if={@suggestions != []}
          class="menu absolute inset-x-0 top-full z-10 -mt-1 rounded-box border border-base-300 bg-base-100 p-1 shadow-lg"
        >
          <li :for={person <- @suggestions}>
            <button
              type="button"
              phx-click="pick-contributor"
              phx-value-path={@contributor.name}
              phx-value-person-id={person.id}
            >
              {person.name}
            </button>
          </li>
        </ul>
      </div>
    </div>
    """
  end
end
