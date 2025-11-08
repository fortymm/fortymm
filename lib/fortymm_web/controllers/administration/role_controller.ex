defmodule FortymmWeb.Administration.RoleController do
  use FortymmWeb, :controller

  alias Fortymm.Administration.Roles

  plug FortymmWeb.Plugs.RequirePermission, "access_administration"

  def index(conn, params) do
    # Parse pagination params
    page = parse_int(params["page"], 1)
    per_page = parse_int(params["per_page"], 20)

    # Parse sort params
    sort_by = parse_sort_field(params["sort_by"], :name)
    sort_order = parse_sort_order(params["sort_order"], :asc)

    # Parse filter params
    search = params["search"]

    # Get roles with filters
    result =
      Roles.list_roles(
        page: page,
        per_page: per_page,
        sort_by: sort_by,
        sort_order: sort_order,
        search: search
      )

    conn
    |> assign(:active_nav, :administration)
    |> assign(:roles, result.roles)
    |> assign(:total, result.total)
    |> assign(:page, result.page)
    |> assign(:per_page, result.per_page)
    |> assign(:total_pages, result.total_pages)
    |> assign(:sort_by, sort_by)
    |> assign(:sort_order, sort_order)
    |> assign(:search, search)
    |> render(:index)
  end

  defp parse_int(nil, default), do: default

  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> max(int, 1)
      _ -> default
    end
  end

  defp parse_int(_value, default), do: default

  defp parse_sort_field(nil, default), do: default

  defp parse_sort_field(value, default) when is_binary(value) do
    case value do
      "id" -> :id
      "name" -> :name
      "description" -> :description
      "inserted_at" -> :inserted_at
      "updated_at" -> :updated_at
      _ -> default
    end
  end

  defp parse_sort_field(_value, default), do: default

  defp parse_sort_order(nil, default), do: default

  defp parse_sort_order(value, default) when is_binary(value) do
    case value do
      "asc" -> :asc
      "desc" -> :desc
      _ -> default
    end
  end

  defp parse_sort_order(_value, default), do: default
end
