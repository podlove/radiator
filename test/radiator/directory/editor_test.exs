defmodule Radiator.EditorTest do
  use Radiator.DataCase

  import Radiator.Factory

  alias Radiator.Directory.Editor
  alias Radiator.Directory.Episode

  test "attach_audio_to_network/2" do
    network = insert(:network)
    audio = insert(:enclosure)

    {:ok, attachment} = Editor.attach_audio_to_network(network, audio)

    assert ^attachment = Ecto.assoc(network, :attachments) |> Repo.one()
    assert ^audio = Ecto.assoc(attachment, :audio) |> Repo.one()
  end

  test "attach_audio_to_episode/2" do
    episode = insert(:episode)
    audio = insert(:enclosure)

    {:ok, attachment} = Editor.attach_audio_to_episode(episode, audio)

    assert ^attachment = Ecto.assoc(episode, :attachments) |> Repo.one()
    assert ^audio = Ecto.assoc(attachment, :audio) |> Repo.one()
    assert ^audio = Ecto.assoc(episode, :audio_files) |> Repo.one()

    %Episode{enclosure: enclosure} = Repo.preload(episode, :enclosure)

    assert ^enclosure = audio
  end
end
