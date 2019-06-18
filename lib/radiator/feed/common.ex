defmodule Radiator.Feed.Common do
  import XmlBuilder
  import Radiator.Feed.Builder, only: [add: 2]

  alias Radiator.Contribution.Person

  def contributor(%Person{} = contributor) do
    element(
      :"atom:contributor",
      [element(:"atom:name", contributor.display_name)] |> add(contributor_uri(contributor))
    )
  end

  def contributor_uri(%Person{uri: uri}) when byte_size(uri) > 0,
    do: element(:"atom:uri", uri)

  def contributor_uri(_), do: nil
end
