defmodule RadiatorWeb.UploadController do
  use RadiatorWeb, :controller

  action_fallback RadiatorWeb.FallbackController

  def create(conn, %{"filename" => filename, "episode_id" => _episode_id}) do
    bucket = Application.get_env(:radiator, :storage_bucket)

    {:ok, upload_url} =
      ExAws.S3.presigned_url(
        ExAws.Config.new(:s3, Application.get_env(:ex_aws, :s3)),
        :put,
        bucket,
        filename
      )

    # i could already put the file name into the episode enclosure field here;
    # although it would be a bit premature in case upload fails

    json(conn, %{"upload_url" => upload_url})
  end

  # very naïve, suboptimal downloading ... but it works!
  def show(conn, %{"filename" => filename, "episode_id" => _episode_id}) do
    bucket = Application.get_env(:radiator, :storage_bucket)

    {:ok, %{status_code: 200, body: body, headers: headers}} =
      ExAws.S3.get_object(bucket, filename)
      |> ExAws.request()

    {_, content_type} = List.keyfind(headers, "Content-Type", 0)

    conn
    |> put_resp_content_type(content_type)
    |> send_resp(200, body)
  end
end
