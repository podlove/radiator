defmodule RadiatorWeb.PodcastComponents do
  @moduledoc """
  Provides components for a podcast.
  """

  use Phoenix.Component

  def episode_list(assigns) do
    ~H"""
    <ol id="episodes-list my-4">
      <li
        :for={episode <- @episodes}
        id={"episode-#{episode.id}"}
        class={[episode.id == @selected && "bg-[#f0f4f4]"]}
      >
        <.link navigate={"/admin/podcast/#{@show_id}/#{episode.id}"} class="flex gap-4 my-4">
          <img src="/images/pic15.jpg" alt="" width="100" />
          {episode.number}
          {episode.title}
          <br />
          {episode.slug}
        </.link>
      </li>
    </ol>
    """
  end
end
