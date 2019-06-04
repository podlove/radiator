defmodule Radiator.EditorTest do
  use Radiator.DataCase

  import Radiator.Factory

  alias Radiator.Directory.Editor

  test "attach_audio_file_to_audio/2" do
    audio = insert(:empty_audio)
    audio_file = insert(:audio_file)

    {:ok, attachment} = Editor.attach_audio_file(audio, audio_file)

    assert ^attachment = Ecto.assoc(audio, :attachments) |> Repo.one()
    assert ^audio = Ecto.assoc(attachment, :audio) |> Repo.one()
    assert ^audio_file = Ecto.assoc(attachment, :audio_file) |> Repo.one()
  end
end
