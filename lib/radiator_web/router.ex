defmodule RadiatorWeb.Router do
  use RadiatorWeb, :router

  import RadiatorWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RadiatorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RadiatorWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/outline", OutlineLive.Index, :index
    live "/outline/:container", OutlineLive.Index, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", RadiatorWeb.Api do
    pipe_through :api

    post "/v1/outline", OutlineController, :create
    get "/raindrop/auth/redirect", RaindropController, :auth_redirect
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:radiator, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RadiatorWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", RadiatorWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{RadiatorWeb.UserAuth, :require_authenticated}] do
      live "/admin", AdminLive.Index, :index
      live "/admin/accounts", AccountsLive.Index, :index
      live "/admin/podcast/:show", EpisodeLive.Index, :index

      live "/admin/podcast/:show/new", EpisodeLive.Index, :new
      live "/admin/podcast/:show/:episode", EpisodeLive.Index, :index
      live "/admin/podcast/:show/:episode/edit", EpisodeLive.Index, :edit

      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", RadiatorWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{RadiatorWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
