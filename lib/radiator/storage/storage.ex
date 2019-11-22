defmodule Radiator.Storage do
  @moduledoc """
  The Storage context.

  Provides direct access to Object Storage (minio). The Radiator.Media API should
  be preferred.

  Can probably access S3 or any other S3 compatible API by changing configuration.
  """

  import Ecto.Query, warn: false

  alias ExAws.S3
  alias Ecto.Multi

  alias Radiator.{
    Repo,
    Storage
  }

  alias Radiator.Storage.FileSlot

  alias Radiator.Directory.{
    Audio,
    Network,
    Podcast
  }

  def create_file(network = %Network{}, uploadable) do
    file_meta = Storage.File.extract_meta(uploadable)

    file =
      %Storage.File{network_id: network.id}
      |> Storage.File.create_changeset(file_meta)

    Multi.new()
    |> Multi.insert(:file, file)
    |> Multi.update(:file_upload, fn %{file: file} ->
      Storage.File.upload_changeset(file, %{file: uploadable})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{file_upload: file}} -> {:ok, file}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def get_file(id) do
    {:ok, Repo.get(Storage.File, id)}
  end

  def list_slots(subject = %Audio{}) do
    slot_names = Audio.slots() |> Enum.map(&to_string/1)

    filled_slots =
      from(slot in Storage.FileSlot,
        where:
          slot.slot in ^slot_names and
            slot.subject_type == "audio" and
            slot.subject_id == ^subject.id,
        preload: :file
      )
      |> Repo.all()

    slot_names
    |> Enum.map(fn slot_name ->
      %{
        slot: slot_name,
        file: maybe_file(slot_name, filled_slots)
      }
    end)
  end

  def get_slot(subject = %Audio{}, slot) when is_atom(slot) do
    get_slot(subject, to_string(slot))
  end

  @doc """
  Get file in slot from subject.
  """
  def get_slot(subject = %Audio{}, slot) do
    with slot_names <- Audio.slots() |> Enum.map(&to_string/1),
         true <- Enum.member?(slot_names, slot),
         {:ok, file} <- get_file_in_slot(subject, slot) do
      {:ok, file}
    else
      false -> {:error, :invalid_slot_name}
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_file_in_slot(subject = %Audio{}, slot) do
    from(slot in Storage.FileSlot,
      where:
        slot.subject_type == "audio" and
          slot.subject_id == ^subject.id and
          slot.slot == ^slot,
      preload: :file
    )
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      s -> {:ok, s.file}
    end
  end

  defp maybe_file(slot_name, filled_slots) do
    Enum.filter(filled_slots, fn slot -> slot.slot == slot_name end)
    |> case do
      [] -> nil
      [slot] -> slot.file
    end
  end

  def fill_slot(subject = %Audio{}, slot, file) do
    Ecto.build_assoc(file, :file_slots)
    |> FileSlot.changeset(%{
      slot: slot,
      subject_type: "audio",
      subject_id: subject.id
    })
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:slot, :subject_type, :subject_id]
    )
  end

  #####
  ## below this is old utility code, needs cleanup.
  #####

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
  def _get_file(key) do
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
