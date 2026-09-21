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

  def card_feature(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body">
        <span class="badge badge-xs badge-warning">Most Popular</span>
        <div class="flex justify-between">
          <h2 class="text-3xl font-bold">Premium</h2>
          <span class="text-xl">$29/mo</span>
        </div>
        <ul class="mt-6 flex flex-col gap-2 text-xs">
          <li>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-4 me-2 inline-block text-success"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            ><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
            <span>High-resolution image generation</span>
          </li>
          <li>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-4 me-2 inline-block text-success"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            ><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
            <span>Customizable style templates</span>
          </li>
          <li>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-4 me-2 inline-block text-success"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            ><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
            <span>Batch processing capabilities</span>
          </li>
          <li>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-4 me-2 inline-block text-success"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            ><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
            <span>AI-driven image enhancements</span>
          </li>
          <li class="opacity-50">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-4 me-2 inline-block text-base-content/50"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            ><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
            <span class="line-through">Seamless cloud integration</span>
          </li>
          <li class="opacity-50">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-4 me-2 inline-block text-base-content/50"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            ><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>
            <span class="line-through">Real-time collaboration tools</span>
          </li>
        </ul>
        <div class="mt-6">
          <button class="btn btn-primary btn-block">Subscribe</button>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :podcast, :any, required: true

  def card_podcast(assigns) do
    ~H"""
    <div id={@id} class="card w-full bg-base-100 shadow-sm">
      <figure :if={@podcast.image_url}>
        <img
          src={@podcast.image_url}
          alt=""
          class="size-full object-cover"
        />
      </figure>
      <div :if={!@podcast.image_url} class="avatar avatar-placeholder">
        <div class="bg-neutral text-neutral-content size-full">
          <CoreComponents.icon name="hero-photo" class="size-8" />
        </div>
      </div>
      <div class="card-body">
        <h2 class="card-title">{@podcast.title}</h2>
        <p>{@podcast.subtitle}</p>
        <div class="card-actions justify-end">
          <.link navigate={~p"/podcast/#{@podcast}"} class="btn btn-block">{gettext("Show")}</.link>
        </div>
      </div>
    </div>
    """
  end

  attr :podcast, :any, required: true
  attr :episode, :any, required: true

  def episode_item(assigns) do
    ~H"""
    <p>
      <.link navigate={~p"/podcast/#{@podcast}/#{@episode}"}>{@episode.title}</.link>
    </p>
    """
  end
end
