defmodule Radiator.Contribution.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contribution_roles" do
    field :title, :string
    field :public?, :boolean, source: :is_public, default: true

    timestamps()
  end

  @doc false
  def changeset(podcast, attrs) do
    podcast
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
