defmodule RadiatorWeb.Admin.Podcasts.FormLive do
  use RadiatorWeb, :live_view

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    podcast = Radiator.Podcasts.get_podcast_by_id!(id)
    form = Radiator.Podcasts.form_to_update_podcast(podcast)

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:page_title, "Edit Podcast")

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    form = Radiator.Podcasts.form_to_create_podcast()

    socket =
      socket
      |> assign(:form, to_form(form))
      |> assign(:page_title, "New Podcast")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app {assigns}>
      <h1>{@page_title}</h1>
      <.form_wrapper
        :let={form}
        id="podcast_form"
        for={@form}
        as={:form}
        phx-change="validate"
        phx-submit="save"
        action_wrapper_class="flex justify-between"
      >
        <.text_field field={form[:title]} label={gettext("Title")} />
        <.text_field field={form[:subtitle]} label={gettext("Subtitle")} />
        <.textarea_field field={form[:summary]} label={gettext("Summary")} />
        <.text_field field={form[:language]} label={gettext("Language")} />
        <.combobox
          field={form[:itunes_type]}
          options={Enum.map(Radiator.Podcasts.ItunesPodcastType.values(), &{&1, &1})}
          label={gettext("Itunes Type")}
        />
        <.text_field field={form[:license_name]} label={gettext("License Name")} />
        <.url_field field={form[:license_url]} label={gettext("License URL")} />
        <.text_field field={form[:author]} label={gettext("Author")} />
        <!-- TODO: Add itunes_category array input -->
        <.checkbox_field
          field={form[:blocked]}
          value="true"
          checked={form[:blocked].value == true}
          label={gettext("Blocked")}
        />
        <.checkbox_field
          field={form[:explicit]}
          value="true"
          checked={form[:explicit].value == true}
          label={gettext("Explicit")}
        />
        <.checkbox_field
          field={form[:complete]}
          value="true"
          checked={form[:complete].value == true}
          label={gettext("Complete")}
        />
        <.url_field field={form[:funding_url]} label={gettext("Donation URL")} />
        <.text_field field={form[:funding_description]} label={gettext("Donation Description")} />
        <:actions>
          <span />
          <.button variant="default" color="primary">Save</.button>
        </:actions>
      </.form_wrapper>
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
      {:ok, podcast} ->
        socket =
          socket
          |> put_flash(:info, gettext("Podcast saved"))
          |> push_navigate(to: ~p"/admin/podcasts/#{podcast}")

        {:noreply, socket}

      {:error, form} ->
        socket =
          socket
          |> put_flash(:error, gettext("Could not save podcast"))
          |> assign(:form, form)

        Logger.error("Could not save podcast: #{inspect(form)}")

        {:noreply, socket}
    end
  end
end
