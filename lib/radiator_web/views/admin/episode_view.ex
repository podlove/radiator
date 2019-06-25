defmodule RadiatorWeb.Admin.EpisodeView do
  use RadiatorWeb, :view

  alias Radiator.Directory.Episode

  import RadiatorWeb.FormatHelpers

  def episode_image_url(episode) do
    Episode.image_url(episode)
  end

  def chapter_image_url(chapter) do
    Radiator.AudioMeta.Chapter.image_url(chapter)
  end
end
