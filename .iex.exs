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
alias Radiator.Directory.{Audio, Episode, Podcast}
alias Radiator.Feed.Builder

alias Radiator.Auth.User

## scratchpad

defmodule Scratchpad do
  alias Ecto.Multi

  def demo_user_avatar do
    user = User |> first |> Repo.one()

    changeset =
      User.changeset(user, %{
        "avatar" => %Plug.Upload{
          content_type: "image/jpeg",
          filename: "#{Ecto.UUID.generate()}.jpg",
          path: "/Users/ericteubert/Downloads/avatar.jpg"
        }
      })

    {:ok, user} = Repo.update(changeset)

    Radiator.Media.UserAvatar.url({user.avatar, user})
    |> IO.inspect(pretty: true)

    Radiator.Media.UserAvatar.url({user.avatar, user}, :icon)
    |> IO.inspect(pretty: true)
  end
end
