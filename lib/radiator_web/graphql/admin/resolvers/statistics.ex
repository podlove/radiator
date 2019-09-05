defmodule RadiatorWeb.GraphQL.Admin.Resolvers.Statistics do
  use Radiator.Constants

  import Absinthe.Resolution.Helpers

  alias Radiator.Reporting

  def get_statistics(subject, _, _) do
    {:ok,
     %{
       downloads: {subject, :downloads}
     }}
  end

  def get_total_statistics({subject, :downloads}, _args, _) do
    {:ok, Reporting.Statistics.get_total_downloads(subject)}
  end

  def get_monthly_statistics({subject, :downloads}, args, _) do
    {:ok, Reporting.Statistics.get_monthly_downloads(subject, args)}
  end

  def get_daily_statistics({subject, :downloads}, args, _) do
    {:ok, Reporting.Statistics.get_daily_downloads(subject, args)}
  end
end
