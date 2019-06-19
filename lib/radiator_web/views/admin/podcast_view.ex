defmodule RadiatorWeb.Admin.PodcastView do
  use RadiatorWeb, :view

  import Radiator.Directory.Editor.Permission, only: [has_permission: 3]

  alias Radiator.Directory.{Episode, Podcast}

  def has_manage_permission_for_network(user, subject) do
    has_permission(user, subject, :manage)
  end

  def podcast_image_url(podcast) do
    Podcast.image_url(podcast)
  end

  def episode_image_url(episode) do
    Episode.image_url(episode)
  end

  def shorten_string(s, max_length, ellipsis \\ "...")
  # used for fields that allow for nil (e.g. Podcast.tagline)
  def shorten_string(nil, _, _) do
    ""
  end

  def shorten_string(s, max_length, ellipsis) when is_binary(s) do
    s
    |> String.split(" ")
    |> Enum.reduce_while("", fn x, prev_string ->
      new_string =
        case prev_string do
          "" -> x
          nonempty_string -> nonempty_string <> " " <> x
        end

      if String.length(new_string) < max_length do
        {:cont, new_string}
      else
        {:halt, prev_string <> ellipsis}
      end
    end)
  end
end
