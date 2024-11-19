defmodule Radiator.Outline.Event.UrlsAnalyzedEvent do
  @moduledoc false
  defstruct [:node_id, :urls, :episode_id, event_id: Ecto.UUID.generate()]
end
