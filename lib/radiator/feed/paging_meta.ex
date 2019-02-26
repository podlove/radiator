defmodule Radiator.Feed.PagingMeta do
  @placeholder ":page:"

  def build(%{episodes: episodes, urls: urls}, opts) do
    with {:amount, items_per_page} when items_per_page > 0 <-
           {:amount, opts[:items_per_page] || 1_000_000},
         {:page, current_page} when current_page > 0 <- {:page, opts[:page] || 1},
         episodes <- Enum.count(episodes),
         pages <- trunc(Float.ceil(episodes / items_per_page)) do
      %{
        items_per_page: items_per_page,
        current_page: current_page,
        total_pages: pages,
        first_page_url: urls.main,
        last_page_url: last_page_url(urls.page_template, pages),
        next_page_url: next_page_url(urls.page_template, current_page, pages),
        prev_page_url: prev_page_url(urls.page_template, current_page)
      }
    else
      {:amount, i} -> raise ArgumentError, "invalid items per page #{i}, must be > 0"
      {:page, p} -> raise ArgumentError, "invalid feed page #{p}, must be > 0"
    end
  end

  defp next_page_url(template, current_page, total_pages) when current_page < total_pages,
    do: String.replace(template, @placeholder, to_string(current_page + 1))

  defp next_page_url(_, _, _),
    do: nil

  defp prev_page_url(template, current_page) when current_page > 1,
    do: String.replace(template, @placeholder, to_string(current_page - 1))

  defp prev_page_url(_, _),
    do: nil

  defp last_page_url(template, total_pages) when total_pages > 1,
    do: String.replace(template, @placeholder, to_string(total_pages))

  defp last_page_url(_, _),
    do: nil
end
