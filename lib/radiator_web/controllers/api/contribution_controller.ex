defmodule RadiatorWeb.Api.ContributionController do
  use RadiatorWeb, :rest_controller

  alias Radiator.Directory.Editor

  alias Radiator.Directory.{
    Podcast,
    Audio
  }

  require Logger

  # TODO: move this into :rest_controller for all rest controllers
  def action(conn, _) do
    args = [conn, conn.params, current_user(conn)]
    apply(__MODULE__, action_name(conn), args)
  end

  def index(conn, _params = %{"contribution" => %{"podcast_id" => id}}, user) do
    with {:ok, contributions} <- Editor.list_contributions(user, %Podcast{id: id}) do
      conn
      |> render("index.json", %{contributions: contributions})
    else
      _ -> @not_found_match
    end
  end

  def index(conn, _params = %{"contribution" => %{"audio_id" => id}}, user) do
    with {:ok, contributions} <- Editor.list_contributions(user, %Audio{id: id}) do
      conn
      |> render("index.json", %{contributions: contributions})
    else
      _ -> @not_found_match
    end
  end

  def index(_conn, _, _) do
    @not_found_match
  end

  def create(conn, %{"contribution" => params = %{"podcast_id" => id}}, user) do
    with {:ok, subject} <- Editor.get_podcast(user, id) do
      do_create(conn, subject, params, user)
    end
  end

  def create(conn, %{"contribution" => params = %{"audio_id" => id}}, user) do
    with {:ok, subject} <- Editor.get_audio(user, id) do
      do_create(conn, subject, params, user)
    end
  end

  def create(_, _, _), do: @not_found_match

  defp do_create(conn, subject = %type{}, params, user) when type in [Podcast, Audio] do
    params = map_contribution_params(params)

    with {:ok, contribution} <- Editor.create_contribution(user, subject, params) do
      conn
      |> put_resp_header("location", Routes.api_contribution_path(conn, :show, contribution))
      |> render("show.json", %{contribution: contribution})
    end
  end

  def show(conn, %{"id" => id}, user) do
    with {:ok, contribution} <- Editor.get_contribution(user, id) do
      conn
      |> render("show.json", %{contribution: contribution})
    end
  end

  def update(conn, %{"id" => id, "contribution" => contribution_params}, user) do
    params = map_contribution_params(contribution_params)

    with {:ok, contribution} <-
           Editor.update_contribution(user, id, params) do
      conn
      |> render("show.json", %{contribution: contribution})
    end
  end

  def delete(conn, %{"id" => id}, user) do
    with {:ok, _contribution} <- Editor.delete_contribution(user, id) do
      send_delete_resp(conn)
    else
      @not_found_match -> send_delete_resp(conn)
      error -> error
    end
  end

  defp map_contribution_params(%{"contribution_role_id" => role_id} = params) do
    params
    |> Map.delete("contribution_role_id")
    |> Map.put("role_id", role_id)
  end

  defp map_contribution_params(params), do: params
end
