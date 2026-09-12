defmodule RadiatorWeb.Admin.PodcastLive.Form do
  use RadiatorWeb, :live_view

  alias AshPhoenix.Form
  alias Radiator.Podcasts.Podcast
  alias Radiator.Podcasts.PodcastType
  alias Radiator.Podcasts.SyncStrategy
  alias RadiatorWeb.Formatting

  @impl true
  def mount(params, _session, socket) do
    podcast =
      case params["id"] do
        nil -> nil
        id -> Ash.get!(Podcast, id, actor: socket.assigns.current_user)
      end

    socket
    |> assign(:return_to, return_to(socket.assigns.live_action, params["return_to"]))
    |> assign(podcast: podcast)
    |> assign(:page_title, page_title(socket.assigns.live_action))
    |> assign_form()
    |> ok()
  end

  defp return_to(_live_action, "show"), do: "show"
  defp return_to(:import, _return_to), do: "show"
  defp return_to(_live_action, _return_to), do: "index"

  defp page_title(:import), do: "Import Podcast"
  defp page_title(:edit), do: "Edit Podcast"
  defp page_title(_live_action), do: "New Podcast"

  @impl true
  def handle_event("validate", %{"podcast" => podcast_params}, socket) do
    socket
    |> assign(form: Form.validate(socket.assigns.form, podcast_params))
    |> noreply()
  end

  def handle_event("add-form", %{"path" => path}, socket) do
    socket
    |> assign(form: Form.add_form(socket.assigns.form, path))
    |> noreply()
  end

  def handle_event("remove-form", %{"path" => path}, socket) do
    socket
    |> assign(form: Form.remove_form(socket.assigns.form, path))
    |> noreply()
  end

  def handle_event("save", %{"podcast" => podcast_params}, socket) do
    case Form.submit(socket.assigns.form, params: podcast_params) do
      {:ok, podcast} ->
        socket
        |> put_flash(:info, saved_message(socket.assigns.live_action))
        |> push_navigate(to: return_path(socket.assigns.return_to, podcast))
        |> noreply()

      {:error, form} ->
        socket |> assign(form: form) |> noreply()
    end
  end

  # `form.source.type` is the action type, which is `:create` for `:import`
  # as well; the live action tells them apart.
  defp saved_message(:import), do: gettext("Podcast angelegt, Feed wird eingelesen.")
  defp saved_message(:edit), do: gettext("Podcast gespeichert.")
  defp saved_message(_live_action), do: gettext("Podcast angelegt.")

  defp assign_form(%{assigns: %{live_action: :import}} = socket) do
    form = Form.for_create(Podcast, :import, as: "podcast", actor: socket.assigns.current_user)

    socket
    |> assign(form: to_form(form))
  end

  defp assign_form(%{assigns: %{podcast: podcast}} = socket) do
    form =
      if podcast do
        Form.for_update(podcast, :update, as: "podcast", actor: socket.assigns.current_user)
      else
        Form.for_create(Podcast, :create, as: "podcast", actor: socket.assigns.current_user)
      end

    socket
    |> assign(form: to_form(form))
  end

  defp return_path("index", _podcast), do: ~p"/admin/podcasts"
  defp return_path("show", nil), do: ~p"/admin/podcasts"
  defp return_path("show", podcast), do: ~p"/admin/podcasts/#{podcast.id}"
end
