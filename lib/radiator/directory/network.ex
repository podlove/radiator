defmodule Radiator.Directory.Network do
  use Ecto.Schema
  import Ecto.Changeset

  schema "networks" do
    field :image, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(network, attrs) do
    network
    |> cast(attrs, [:title, :image])
    |> validate_required([:title])
  end
end
