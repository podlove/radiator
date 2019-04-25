defmodule Radiator.EditorTest do
  use Radiator.DataCase

  import Radiator.Factory

  alias Radiator.Directory.Editor

  test "attach_audio_to_network/2" do
    network = insert(:network)
    audio = insert(:enclosure)

    {:ok, attachment} = Editor.attach_audio_to_network(network, audio)

    assert ^attachment = Ecto.assoc(network, :attachments) |> Repo.one()
    assert ^audio = Ecto.assoc(attachment, :audio) |> Repo.one()
  end
end
