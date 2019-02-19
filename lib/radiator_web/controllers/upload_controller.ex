defmodule RadiatorWeb.UploadController do
  use RadiatorWeb, :controller

  action_fallback RadiatorWeb.FallbackController

  def create(conn, %{"filename" => filename, "episode_id" => _episode_id}) do
    bucket = Application.get_env(:radiator, :storage_bucket)
    presign_endpoint = Application.get_env(:radiator, :storage_presign_endpoint)

    # fixme: don't override existing uploads with same name
    # - prefix with episode id
    # - or prefix with a short uuid
    upload_url =
      presign_endpoint
      |> set_url_params(%{"name" => filename, "bucket" => bucket})
      |> HTTPoison.get!()
      |> Map.get(:body)

    json(conn, %{"upload_url" => upload_url})
  end

  defp set_url_params(url, params) when is_binary(url) and is_map(params) do
    url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(params))
    |> URI.to_string()
  end
end
