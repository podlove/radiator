defmodule RadiatorWeb.Helpers.AdminResourceHelpers do
  @moduledoc """
  Admin resource helper functions for the web layer.
  """
  use Radiator.Constants, :general

  import Plug.Conn

  import RadiatorWeb.Helpers.AuthHelpers, only: [current_user: 1]
  alias Radiator.Directory.Editor
  alias Radiator.Directory.Network

  alias RadiatorWeb.Router.Helpers, as: Routes

  @network_assign :current_network
  @podcast_assign :current_podcast
  @resource_stack_assign :current_resource_stack

  def current_network(conn) do
    conn.assigns[@network_assign]
  end

  def current_podcast(conn) do
    conn.assigns[@podcast_assign]
  end

  def current_resource_stack(conn) do
    conn.assigns[@resource_stack_assign]
  end

  def load_current_admin_resources(conn) do
    actor = current_user(conn)

    # TODO: optimize by just getting the deepest resource first and preload the stack

    {conn, resource_stack} =
      [conn.path_params["network_id"], conn.path_params["podcast_id"]]
      |> Enum.reduce({conn, []}, fn
        _, {_conn, :error} = acc ->
          acc

        nil, acc ->
          acc

        network_id, {conn, []} ->
          id = String.to_integer(network_id)

          with {:ok, network} <- Editor.get_network(actor, id) do
            {assign(conn, @network_assign, network), [network]}
          else
            @not_authorized_match ->
              handle_error_and_redirect(
                conn,
                Routes.admin_network_path(conn, :index),
                "Account #{actor.name} is not authorized for this resource."
              )

            {:error, error} ->
              handle_error_and_redirect(
                conn,
                Routes.admin_network_path(conn, :index),
                "Debug Error: #{inspect(error, pretty: true)}"
              )
          end

        podcast_id, {conn, [network = %Network{}]} ->
          id = String.to_integer(podcast_id)

          with {:ok, podcast} <- Editor.get_podcast(actor, id) do
            {assign(conn, @podcast_assign, podcast), [network, podcast]}
          else
            @not_authorized_match ->
              handle_error_and_redirect(
                conn,
                Routes.admin_network_path(conn, :show, network.id),
                "Account #{actor.name} is not authorized for this resource."
              )

            {:error, error} ->
              handle_error_and_redirect(
                conn,
                Routes.admin_network_path(conn, :show, network.id),
                "Debug Error: #{inspect(error, pretty: true)}"
              )
          end
      end)

    resource_stack =
      if is_list(resource_stack) do
        resource_stack
      else
        []
      end

    assign(conn, @resource_stack_assign, resource_stack)
  end

  defp handle_error_and_redirect(conn, target_path, error_string) do
    conn
    |> Phoenix.Controller.put_flash(:error, error_string)
    |> Phoenix.Controller.redirect(to: target_path)
    |> halt()
    |> (&{&1, :error}).()
  end
end
