defmodule RadiatorWeb.SharedPartialsView do
  use RadiatorWeb, :view

  import RadiatorWeb.ContentHelpers

  use Radiator.Constants, :permissions

  def permission_select_values do
    @permission_values
    |> Enum.map(fn perm ->
      {format_permission(perm), perm}
    end)
    |> Enum.to_list()
  end
end
