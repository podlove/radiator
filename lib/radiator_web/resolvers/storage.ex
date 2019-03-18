defmodule RadiatorWeb.Resolvers.Storage do
  alias Radiator.Storage

  def create_upload(_parent, %{filename: filename}, _resolution) do
    {:ok, upload_url} = Storage.get_upload_url(filename)
    {:ok, %{upload_url: upload_url}}
  end
end
