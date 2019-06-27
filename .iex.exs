global_settings = "~/.iex.exs"
if File.exists?(global_settings), do: Code.require_file(global_settings)

Application.put_env(:elixir, :ansi_enabled, true)

IEx.configure(
  colors: [
    eval_result: [:cyan, :bright],
    eval_error: [[:red, :bright, "\n▶▶▶\n"]],
    eval_info: [:yellow, :bright]
  ],
  default_prompt:
    [
      # cursor ⇒ column 1
      "\e[G",
      :white,
      "%prefix",
      :cyan,
      "|",
      :white,
      "%counter",
      " ",
      :cyan,
      "▶",
      :reset
    ]
    |> IO.ANSI.format()
    |> IO.chardata_to_string()
)

import Ecto.Query, warn: false

alias RadiatorWeb.Router.Helpers, as: Routes

alias Radiator.{Directory, Repo, Storage}
alias Radiator.Directory.{Audio, Episode, Podcast, Network, Editor}

alias Radiator.Media
alias Radiator.Media.AudioFile

alias Radiator.Feed.Builder

alias Radiator.Auth
alias Radiator.Auth.User

alias Radiator.Contribution
alias Radiator.Contribution.Person

alias Radiator.Perm.Ecto.PermissionType
alias Radiator.Perm.Permission

defmodule H do
  def create_episode_audio(episode) do
    upload = %Plug.Upload{
      path: "test/fixtures/pling.mp3",
      filename: "pling.mp3"
    }

    {:ok, audio_file} = Media.AudioFileUpload.upload(upload, episode)

    audio_file
  end
end
