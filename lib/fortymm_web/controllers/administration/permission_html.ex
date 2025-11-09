defmodule FortymmWeb.Administration.PermissionHTML do
  @moduledoc """
  This module contains pages rendered by Administration.PermissionController.
  """
  use FortymmWeb, :html
  import FortymmWeb.PaginationComponents

  embed_templates "permission_html/*"

  @doc """
  Generates a sort link for table headers.
  """
  def sort_link(assigns) do
    ~H"""
    <a
      href={build_sort_url(@conn, @field, @current_sort_by, @current_sort_order, @search)}
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

  defp build_sort_url(conn, field, current_sort_by, current_sort_order, search) do
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

    "#{conn.request_path}?#{URI.encode_query(query_params)}"
  end
end
