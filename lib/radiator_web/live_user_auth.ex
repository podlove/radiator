defmodule RadiatorWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  use RadiatorWeb, :verified_routes

  alias AshAuthentication.Phoenix.LiveSession

  # Clauses are dispatched via a single `on_mount/4` head with an
  # internal `case` rather than separate function heads. Multiple
  # `on_mount/4` heads trigger pathological compile-time slowdowns in
  # Elixir 1.19+'s type checker during router verification.
  #
  # This is used for nested liveviews to fetch the current user.
  # To use, place the following at the top of that liveview:
  # on_mount {RadiatorWeb.LiveUserAuth, :current_user}
  def on_mount(action, _params, session, socket) do
    case action do
      :current_user ->
        {:cont, LiveSession.assign_new_resources(socket, session)}

      :live_user_optional ->
        if socket.assigns[:current_user] do
          {:cont, socket}
        else
          {:cont, assign(socket, :current_user, nil)}
        end

      :live_user_required ->
        if socket.assigns[:current_user] do
          {:cont, socket}
        else
          {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
        end

      :live_no_user ->
        if socket.assigns[:current_user] do
          {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
        else
          {:cont, assign(socket, :current_user, nil)}
        end
    end
  end
end
