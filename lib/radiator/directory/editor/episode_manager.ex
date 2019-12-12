defmodule Radiator.Directory.Editor.EpisodeManager do
  @moduledoc """
  Not sure yet where to put this but I feel like it's worth
  having a dedicated module to the whole episode management
  stuff. Maybe even just for episode creation.

  As it is now it could go up a layer.

  TODO: Refactor, possibly split up, move around. Document usage.

  See RadiatorWeb.Admin.EpisodeController#create for example usage.
  """
  alias Ecto.Multi

  alias Radiator.{
    Repo,
    Storage
  }

  alias Radiator.Storage.FileSlot

  alias Radiator.Directory.{
    Network,
    Podcast,
    Episode,
    Audio
  }

  def create_episode_with_upload(podcast, episode_attrs, audio_attrs, uploadable, slot_name) do
    with {:ok, %{episode: episode, audio: audio}} <-
           create_episode_with_audio(podcast, episode_attrs, audio_attrs),
         network <- Ecto.assoc(episode, [:podcast, :network]) |> Repo.one(),
         {:ok, result} <- upload_file_to_audio_slot(network, uploadable, audio, slot_name) do
      {:ok, result |> Map.put(:episode, episode) |> Map.put(:audio, audio)}
    end
  end

  def create_episode_with_audio(podcast, episode_attrs, audio_attrs) do
    Multi.new()
    |> Multi.insert(:episode, create_episode_changeset(podcast, episode_attrs))
    |> Multi.insert(:audio, create_audio_changeset(audio_attrs))
    |> Multi.update(:attached_episode, fn %{episode: episode, audio: audio} ->
      attach_audio_to_episode_changeset(episode, audio)
    end)
    |> Repo.transaction()
  end

  def upload_file_to_audio_slot(_network, nil, _audio, _slot_name) do
    {:ok, %{}}
  end

  def upload_file_to_audio_slot(network, uploadable, audio, slot_name) do
    Multi.new()
    |> Multi.insert(:file, create_file_changeset(network, uploadable))
    |> Multi.update(:upload, fn %{file: file} -> upload_file_changeset(file, uploadable) end)
    |> Multi.insert(
      :fill_slot,
      fn %{file: file} ->
        fill_slot_changeset(audio, slot_name, file)
      end,
      on_conflict: :replace_all,
      conflict_target: [:slot, :subject_type, :subject_id]
    )
    |> Repo.transaction()
  end

  def create_episode_changeset(podcast = %Podcast{}, attrs \\ %{}) do
    podcast
    |> Ecto.build_assoc(:episodes)
    |> Episode.changeset(attrs)
  end

  def create_audio_changeset(attrs \\ %{}) do
    Audio.changeset(%Audio{}, attrs)
  end

  def attach_audio_to_episode_changeset(episode = %Episode{}, audio = %Audio{}) do
    Episode.set_audio_changeset(episode, %{audio_id: audio.id})
  end

  # file creation stuff doesn't belong here
  # but it's a good place to bootstrap it for the "create episode" use case

  def create_file_changeset(network = %Network{}, uploadable) do
    file_meta = Storage.File.extract_meta(uploadable)

    %Storage.File{network_id: network.id}
    |> Storage.File.create_changeset(file_meta)
  end

  def upload_file_changeset(file, uploadable) do
    Storage.File.upload_changeset(file, %{file: uploadable})
  end

  def fill_slot_changeset(subject = %Audio{}, slot_name, file) do
    file
    |> Ecto.build_assoc(:file_slots)
    |> FileSlot.changeset(%{
      slot: slot_name,
      subject_type: "audio",
      subject_id: subject.id
    })
  end
end
