defmodule Radiator.Repo.Migrations.CreateFileSlots do
  use Ecto.Migration

  def change do
    create table(:file_slots) do
      add :slot, :string
      add :subject_type, :string
      add :subject_id, :integer

      add :file_id, references(:files, type: :uuid, on_delete: :delete_all)

      timestamps()
    end
  end
end
