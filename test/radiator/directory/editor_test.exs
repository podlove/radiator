defmodule Radiator.EditorTest do
  use Radiator.DataCase

  import Radiator.Factory

  alias Radiator.Directory.Editor

  test "attach_audio_file_to_audio/2" do
    audio = insert(:empty_audio)
    audio_file = insert(:audio_file)

    {:ok, audio_file} = Editor.attach_audio_file(audio, audio_file)

    assert audio_file.id == Ecto.assoc(audio, :audio_files) |> Repo.one() |> Map.get(:id)
  end
end
