defmodule RadiatorWeb.Admin.Shows.FormLive do
  use RadiatorWeb, :live_view

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    show = Radiator.Podcasts.get_show_by_id!(id)
    form = Radiator.Podcasts.form_to_update_show(show)

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:page_title, "Edit Show")

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    form = Radiator.Podcasts.form_to_create_show()

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:page_title, "New Show")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <h1>{@page_title}</h1>
      <.simple_form
        :let={form}
        id="show_form"
        as={:form}
        for={@form}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={form[:title]} label={gettext("Title")} />
        <.input field={form[:subtitle]} label={gettext("Subtitle")} />
        <.input field={form[:summary]} label={gettext("Summary")} />
        <.input field={form[:language]} label={gettext("Language")} />
        <.input
          field={form[:itunes_type]}
          type="select"
          options={Radiator.Podcasts.ItunesShowType.values()}
          label={gettext("Itunes Type")}
        />
        <.input field={form[:license_name]} label={gettext("License Name")} />
        <.input field={form[:license_url]} label={gettext("License URL")} />
        <.input field={form[:author]} label={gettext("Author")} />
        <!-- TODO: Add itunes category array input -->
        <.input field={form[:blocked]} type="checkbox" label={gettext("Blocked")} />
        <.input field={form[:explicit]} type="checkbox" label={gettext("Explicit")} />
        <.input field={form[:complete]} type="checkbox" label={gettext("Complete")} />
        <.input field={form[:funding_url]} label={gettext("Donation URL")} />
        <.input field={form[:funding_description]} label={gettext("Donation Description")} />
        <:actions>
          <.button variant="primary">Save</.button>
        </:actions>
      </.simple_form>
    </Layouts.app>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"form" => form_data}, socket) do
    socket = update(socket, :form, &AshPhoenix.Form.validate(&1, form_data))
    {:noreply, socket}
  end

  def handle_event("save", %{"form" => form_data}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form, params: form_data) do
      {:ok, show} ->
        socket =
          socket
          |> put_flash(:info, gettext("Show saved"))
          |> push_navigate(to: ~p"/admin/shows/#{show}")

        {:noreply, socket}

      {:error, form} ->
        socket =
          socket
          |> put_flash(:error, gettext("Could not save show"))
          |> assign(:form, form)

        Logger.error("Could not save show: #{inspect(form)}")

        {:noreply, socket}
    end
  end
end
