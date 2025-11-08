defmodule FortymmWeb.Administration.UserController do
  use FortymmWeb, :controller

  alias Fortymm.Administration.Users

  plug FortymmWeb.Plugs.RequirePermission, "access_administration"

  def index(conn, params) do
    # Parse pagination params
    page = parse_int(params["page"], 1)
    per_page = parse_int(params["per_page"], 20)

    # Parse sort params
    sort_by = parse_sort_field(params["sort_by"], :inserted_at)
    sort_order = parse_sort_order(params["sort_order"], :desc)

    # Parse filter params
    search = params["search"]
    role_id = params["role_id"]

    # Get users with filters
    result =
      Users.list_users(
        page: page,
        per_page: per_page,
        sort_by: sort_by,
        sort_order: sort_order,
        search: search,
        role_id: role_id
      )

    # Get roles for filter dropdown
    roles = Users.list_roles()

    conn
    |> assign(:active_nav, :administration)
    |> assign(:users, result.users)
    |> assign(:total, result.total)
    |> assign(:page, result.page)
    |> assign(:per_page, result.per_page)
    |> assign(:total_pages, result.total_pages)
    |> assign(:sort_by, sort_by)
    |> assign(:sort_order, sort_order)
    |> assign(:search, search)
    |> assign(:role_id, role_id)
    |> assign(:roles, roles)
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
      "email" -> :email
      "username" -> :username
      "inserted_at" -> :inserted_at
      "updated_at" -> :updated_at
      "confirmed_at" -> :confirmed_at
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
