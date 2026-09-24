defmodule RadiatorWeb.CustomComponents do
  @moduledoc """
  Application-specific components.
  """
  use Phoenix.Component
  use Gettext, backend: RadiatorWeb.Gettext
  use RadiatorWeb, :verified_routes

  alias RadiatorWeb.CoreComponents

  @doc """
  Drawer is a grid layout that can show/hide a sidebar on the left or right side of the page.

  ## Examples

      <.drawer>content</.drawer>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def drawer(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open">
      <input id="my-drawer-4" type="checkbox" class="drawer-toggle inline" />
      <div class="drawer-content">
        <nav class="navbar w-full bg-base-300">
          <label
            for="my-drawer-4"
            aria-label="open sidebar"
            class="btn btn-square btn-ghost drawer-button"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              stroke-linejoin="round"
              stroke-linecap="round"
              stroke-width="2"
              fill="none"
              stroke="currentColor"
              class="my-1.5 inline-block size-4"
            ><path d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2z">
            </path><path d="M9 4v16"></path><path d="M14 10l2 2l-2 2"></path></svg>
          </label>
          <div class="px-4">Navbar Title</div>
        </nav>
        <div class="p-4">
          {render_slot(@inner_block)}
        </div>
      </div>

      <div class="drawer-side is-drawer-close:overflow-visible">
        <label for="my-drawer-4" aria-label="close sidebar" class="drawer-overlay"></label>
        <div class="flex min-h-full flex-col items-start bg-base-200 is-drawer-close:w-14 is-drawer-open:w-64">
          <ul class="menu w-full grow">
            <li>
              <button
                class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
                data-tip="Episodes"
              >
                <CoreComponents.icon name="hero-list-bullet" class="size-5" />
                <span class="is-drawer-close:hidden">Episodes</span>
              </button>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  A podcast tile for listeners: cover, description, episode count and the date of
  the latest episode. The whole tile links to the podcast page.

  Expects the `:episode_count` and `:latest_episode_at` aggregates to be loaded.
  """
  attr :id, :string, required: true
  attr :podcast, :any, required: true

  def podcast_tile(assigns) do
    ~H"""
    <.link
      id={@id}
      navigate={~p"/podcasts/#{@podcast}"}
      class="group flex flex-col gap-3 rounded-box outline-offset-4 focus-visible:outline-2 focus-visible:outline-primary"
    >
      <div class="overflow-hidden rounded-box bg-base-300">
        <img
          :if={@podcast.image_url}
          src={@podcast.image_url}
          alt=""
          loading="lazy"
          class="aspect-square size-full object-cover transition-transform duration-300 motion-safe:group-hover:scale-105"
        />
        <div :if={!@podcast.image_url} class="grid aspect-square place-items-center">
          <CoreComponents.icon name="hero-microphone" class="size-10 opacity-40" />
        </div>
      </div>

      <div class="space-y-1.5">
        <h2 class="leading-snug font-semibold text-balance transition-colors group-hover:text-primary">
          {@podcast.title}
        </h2>
        <p :if={description(@podcast)} class="line-clamp-3 text-sm opacity-75">
          {description(@podcast)}
        </p>
      </div>

      <div class="mt-auto text-xs opacity-60">
        <p :if={@podcast.episode_count > 0}>
          {ngettext("1 Folge", "%{count} Folgen", @podcast.episode_count)}
        </p>
        <p :if={@podcast.episode_count == 0}>{gettext("Noch keine Folgen")}</p>
        <p :if={@podcast.latest_episode_at}>
          {gettext("Letzte Folge am %{date}", date: format_date(@podcast.latest_episode_at))}
        </p>
      </div>
    </.link>
    """
  end

  defp description(%{summary: summary}) when is_binary(summary) and summary != "", do: summary
  defp description(%{subtitle: subtitle}), do: subtitle

  defp format_date(datetime), do: Calendar.strftime(datetime, "%d.%m.%Y")

  attr :podcast, :any, required: true
  attr :episode, :any, required: true

  def episode_item(assigns) do
    ~H"""
    <p>
      <.link navigate={~p"/podcasts/#{@podcast}/#{@episode}"}>{@episode.title}</.link>
    </p>
    """
  end
end
