defmodule Radiator.Outline.Event.UrlsAnalyzedEvent do
  @moduledoc false
  defstruct [:node_id, :urls, :outline_node_container_id, event_id: Ecto.UUID.generate()]
end
