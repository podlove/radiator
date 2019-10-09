defmodule Radiator.Storage do
  @moduledoc """
  The Storage context.

  Provides direct access to Object Storage (minio). The Radiator.Media API should
  be preferred.

  Can probably access S3 or any other S3 compatible API by changing configuration.
  """

  alias ExAws.S3
  alias Radiator.Directory.Podcast

  def list_files() do
    {:ok, %{status_code: 200, body: %{contents: contents}, headers: _headers}} =
      S3.list_objects(bucket()) |> ExAws.request()

    files =
      contents
      |> Enum.map(fn object ->
        {:ok, last_modified, _} = DateTime.from_iso8601(object.last_modified)

        %{
          key: object.key,
          size: String.to_integer(object.size),
          last_modified: last_modified
        }
      end)

    {:ok, files}
  end

  @doc """
  Return tuple `{:ok, file_content, headers}`.
  """
  def get_file(key) do
    {:ok, %{status_code: 200, body: body, headers: headers}} =
      S3.get_object(bucket(), key) |> ExAws.request()

    {:ok, body, Enum.into(headers, Map.new())}
  end

  @doc """
  Return file headers.
  """
  def get_file_headers(key) do
    {:ok, %{status_code: 200, headers: headers}} =
      S3.head_object(bucket(), key) |> ExAws.request()

    {:ok, Enum.into(headers, Map.new())}
  end

  def get_upload_url(key) do
    {:ok, upload_url} =
      S3.presigned_url(
        ExAws.Config.new(:s3, Application.get_env(:ex_aws, :s3)),
        :put,
        bucket(),
        key
      )

    {:ok, upload_url}
  end

  def upload_file(source, destination, content_type) do
    source
    |> S3.Upload.stream_file()
    |> S3.upload(bucket(), destination, content_type: content_type)
    |> ExAws.request!()
  end

  def delete_file(key) do
    {:ok, _} = S3.delete_object(bucket(), key) |> ExAws.request()

    {:ok, key}
  end

  def list_feed_files(podcast_id) do
    {:ok, %{status_code: 200, body: %{contents: contents}, headers: _headers}} =
      S3.list_objects(bucket(), prefix: "feed/#{podcast_id}") |> ExAws.request()

    contents = contents |> Enum.map(fn f -> {f.key, f.last_modified} end)

    {:ok, contents}
  end

  @doc """
  Full storage URL for a given file name
  """
  def file_url(%Podcast{} = podcast, filename) do
    url_base() <> file_path(podcast, filename)
  end

  @doc """
  File path relative to bucket.
  """
  def file_path(%Podcast{} = podcast, filename) do
    "/p#{podcast.id}/#{filename}"
  end

  @doc """
  Base storage URL, including bucket.
  """
  def url_base() do
    [scheme: scheme, host: host, port: port] = Application.fetch_env!(:ex_aws, :s3)
    scheme = String.replace(scheme, "://", "")

    struct(URI, scheme: scheme, host: host, port: port, path: "/#{bucket()}")
    |> URI.to_string()
  end

  defp bucket do
    Application.get_env(:radiator, :storage_bucket)
  end
end
