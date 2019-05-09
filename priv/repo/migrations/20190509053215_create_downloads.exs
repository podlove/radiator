defmodule Radiator.Repo.Migrations.CreateDownloads do
  use Ecto.Migration

  def change do
    create table(:downloads) do
      add :request_id, :string
      add :accessed_at, :utc_datetime
      add :clean, :boolean, default: false, null: false
      add :httprange, :string
      add :context, :string

      add :user_agent, :text
      add :user_agent_bot, :boolean, default: false, null: false
      add :user_agent_client_name, :string
      add :user_agent_client_type, :string
      add :user_agent_os_name, :string
      add :user_agent_device_type, :string
      add :user_agent_device_model, :string

      add :hours_since_published, :integer

      add :network_id, references(:networks, on_delete: :nothing)
      add :podcast_id, references(:podcasts, on_delete: :nothing)
      add :episode_id, references(:episodes, on_delete: :nothing)

      timestamps()
    end

    create index(:downloads, [:network_id])
    create index(:downloads, [:podcast_id])
    create index(:downloads, [:episode_id])
  end
end
