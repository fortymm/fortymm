defmodule FortymmWeb.Administration.UserHTML do
  @moduledoc """
  This module contains pages rendered by Administration.UserController.
  """
  use FortymmWeb, :html

  embed_templates "user_html/*"

  @doc """
  Generates a sort link for table headers.
  """
  def sort_link(assigns) do
    ~H"""
    <a
      href={build_sort_url(@conn, @field, @current_sort_by, @current_sort_order, @search, @role_id)}
      class="flex items-center gap-1 hover:opacity-70 cursor-pointer"
    >
      {@label}
      <%= if @field == @current_sort_by do %>
        <%= if @current_sort_order == :asc do %>
          <.icon name="hero-chevron-up" class="w-4 h-4" />
        <% else %>
          <.icon name="hero-chevron-down" class="w-4 h-4" />
        <% end %>
      <% else %>
        <.icon name="hero-chevron-up-down" class="w-4 h-4 opacity-30" />
      <% end %>
    </a>
    """
  end

  defp build_sort_url(conn, field, current_sort_by, current_sort_order, search, role_id) do
    # Toggle sort order if clicking same field, otherwise default to asc
    sort_order =
      if field == current_sort_by do
        if current_sort_order == :asc, do: :desc, else: :asc
      else
        :asc
      end

    query_params = %{
      "sort_by" => Atom.to_string(field),
      "sort_order" => Atom.to_string(sort_order)
    }

    query_params =
      if search && search != "" do
        Map.put(query_params, "search", search)
      else
        query_params
      end

    query_params =
      if role_id && role_id != "" do
        Map.put(query_params, "role_id", role_id)
      else
        query_params
      end

    "#{conn.request_path}?#{URI.encode_query(query_params)}"
  end

  @doc """
  Generates pagination links.
  """
  def pagination_links(assigns) do
    ~H"""
    <div class="card-body border-t border-base-300">
      <div class="flex flex-col sm:flex-row items-center justify-between gap-4">
        <div class="text-sm">
          Showing <span class="font-semibold">{(@page - 1) * @per_page + 1}</span>
          to <span class="font-semibold">{min(@page * @per_page, @total)}</span>
          of <span class="font-semibold">{@total}</span>
          results
        </div>

        <div class="join">
          <%= if @page > 1 do %>
            <a
              href={build_page_url(@conn, @page - 1, @sort_by, @sort_order, @search, @role_id)}
              class="join-item btn btn-sm"
            >
              <.icon name="hero-chevron-left" class="w-4 h-4" />
            </a>
          <% else %>
            <button class="join-item btn btn-sm btn-disabled">
              <.icon name="hero-chevron-left" class="w-4 h-4" />
            </button>
          <% end %>

          <%= for page_num <- page_range(@page, @total_pages) do %>
            <%= if page_num == @page do %>
              <button class="join-item btn btn-sm btn-active">{page_num}</button>
            <% else %>
              <a
                href={build_page_url(@conn, page_num, @sort_by, @sort_order, @search, @role_id)}
                class="join-item btn btn-sm"
              >
                {page_num}
              </a>
            <% end %>
          <% end %>

          <%= if @page < @total_pages do %>
            <a
              href={build_page_url(@conn, @page + 1, @sort_by, @sort_order, @search, @role_id)}
              class="join-item btn btn-sm"
            >
              <.icon name="hero-chevron-right" class="w-4 h-4" />
            </a>
          <% else %>
            <button class="join-item btn btn-sm btn-disabled">
              <.icon name="hero-chevron-right" class="w-4 h-4" />
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp build_page_url(conn, page, sort_by, sort_order, search, role_id) do
    query_params = %{
      "page" => Integer.to_string(page),
      "sort_by" => Atom.to_string(sort_by),
      "sort_order" => Atom.to_string(sort_order)
    }

    query_params =
      if search && search != "" do
        Map.put(query_params, "search", search)
      else
        query_params
      end

    query_params =
      if role_id && role_id != "" do
        Map.put(query_params, "role_id", role_id)
      else
        query_params
      end

    "#{conn.request_path}?#{URI.encode_query(query_params)}"
  end

  defp page_range(current_page, total_pages) do
    # Show 5 pages at a time
    half_range = 2

    start_page = max(1, current_page - half_range)
    end_page = min(total_pages, current_page + half_range)

    # Adjust if we're at the beginning or end
    start_page =
      if end_page == total_pages && total_pages > 5 do
        max(1, total_pages - 4)
      else
        start_page
      end

    end_page =
      if start_page == 1 && total_pages > 5 do
        min(5, total_pages)
      else
        end_page
      end

    Enum.to_list(start_page..end_page)
  end
end
