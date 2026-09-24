defmodule RadiatorWeb.Router do
  use RadiatorWeb, :router

  use AshAuthentication.Phoenix.Router

  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RadiatorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
    plug :set_scope, scope: Radiator.Accounts.Scope, default_scope?: true
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_scope, scope: Radiator.Accounts.Scope, default_scope?: true

    plug AshAuthentication.Strategy.ApiKey.Plug,
      resource: Radiator.Accounts.User,
      # if you want to require an api key to be supplied, set `required?` to true
      required?: false
  end

  scope "/", RadiatorWeb do
    pipe_through :browser

    ash_authentication_live_session :public_routes,
      scope: Radiator.Accounts.Scope,
      default_scope: :user,
      on_mount: {RadiatorWeb.LiveUserAuth, :live_user_optional} do
      live "/", HomeLive.Index, :index

      live "/podcasts", PodcastLive.Index, :index
      live "/podcasts/:podcast", PodcastLive.Show, :index
      live "/podcasts/:podcast/:episode", EpisodeLive.Index, :show

      get "/impressum", PageController, :imprint
    end

    auth_routes AuthController, Radiator.Accounts.User, path: "/auth"

    sign_out_route AuthController, "/sign-out",
      overrides: [RadiatorWeb.AuthOverrides, AshAuthentication.Phoenix.Overrides.Default]

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{RadiatorWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    RadiatorWeb.AuthOverrides,
                    AshAuthentication.Phoenix.Overrides.Default
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  RadiatorWeb.AuthOverrides,
                  AshAuthentication.Phoenix.Overrides.Default
                ]

    # Remove this if you do not use the confirmation strategy
    confirm_route Radiator.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [RadiatorWeb.AuthOverrides, AshAuthentication.Phoenix.Overrides.Default]

    # Remove this if you do not use the magic link strategy.
    magic_sign_in_route(Radiator.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [RadiatorWeb.AuthOverrides, AshAuthentication.Phoenix.Overrides.Default]
    )
  end

  scope "/admin", RadiatorWeb.Admin do
    pipe_through :browser

    # ash_authentication_live_session :authenticated_routes,
    #   scope: Radiator.Accounts.Scope,
    #   default_scope: :user do
    #   in each liveview, add one of the following at the top of the module:
    #
    #   If an authenticated user must be present:
    #   on_mount {RadiatorWeb.LiveUserAuth, :live_user_required}
    #
    #   If an authenticated user *may* be present:
    #   on_mount {RadiatorWeb.LiveUserAuth, :live_user_optional}
    #
    #   If an authenticated user must *not* be present:
    #   on_mount {RadiatorWeb.LiveUserAuth, :live_no_user}
    # end

    ash_authentication_live_session :authenticated_routes,
      scope: Radiator.Accounts.Scope,
      default_scope: :user,
      on_mount: {RadiatorWeb.LiveUserAuth, :live_user_required} do
      live "/", HomeLive.Index, :index

      live "/podcasts", PodcastLive.Index, :index
      live "/podcasts/new", PodcastLive.Form, :new
      live "/podcasts/import", PodcastLive.Form, :import
      live "/podcasts/:id/edit", PodcastLive.Form, :edit

      live "/podcasts/:id", PodcastLive.Show, :show
      live "/podcasts/:id/show/edit", PodcastLive.Show, :edit

      live "/podcasts/:podcast_id/episodes/new", EpisodeLive.Form, :new
      live "/podcasts/:podcast_id/episodes/:id/edit", EpisodeLive.Form, :edit
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", RadiatorWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:radiator, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import AshAdmin.Router
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RadiatorWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview

      ash_admin "/ash_admin"

      oban_dashboard("/oban")
    end
  end
end
