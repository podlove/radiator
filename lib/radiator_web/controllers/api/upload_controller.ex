defmodule RadiatorWeb.Api.UploadController do
  use RadiatorWeb, :controller

  alias Radiator.Storage

  action_fallback RadiatorWeb.Api.FallbackController

  def create(conn, %{"filename" => filename}) do
    {:ok, upload_url} = Storage.get_upload_url(filename)
    json(conn, %{"upload_url" => upload_url})
  end
end
