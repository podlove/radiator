defmodule Radiator.Media do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query, warn: false

  alias Radiator.Repo
  alias Radiator.Media.AudioFile

  def get_audio_file(id), do: Repo.get(AudioFile, id)

  def create_audio_file(attrs \\ %{}) do
    %AudioFile{}
    |> AudioFile.changeset(attrs)
    |> Repo.insert()
  end
end
