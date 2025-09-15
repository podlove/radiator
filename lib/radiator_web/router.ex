defmodule RadiatorWeb.Router do
  use RadiatorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RadiatorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RadiatorWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/admin", RadiatorWeb.Admin do
    pipe_through :browser

    live "/shows", Shows.IndexLive
    live "/shows/new", Shows.FormLive, :new
    live "/shows/:id", Shows.ShowLive
    live "/shows/:id/edit", Shows.FormLive, :edit

    live "/shows/:show_id/episodes/new", Episodes.FormLive, :new
    live "/shows/:show_id/episodes", Episodes.IndexLive
    live "/shows/:show_id/episodes/:id", Episodes.ShowLive
    live "/shows/:show_id/episodes/:id/edit", Episodes.FormLive, :edit
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
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RadiatorWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  if Application.compile_env(:radiator, :dev_routes) do
    import AshAdmin.Router

    scope "/ash_admin" do
      pipe_through :browser

      ash_admin "/"
    end
  end
end
