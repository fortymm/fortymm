defmodule FortymmWeb.Administration.RoleController do
  use FortymmWeb, :controller

  import FortymmWeb.PaginationHelpers

  alias Fortymm.Administration.Roles
  alias Fortymm.Pagination

  plug FortymmWeb.Plugs.RequirePermission, "access_administration"

  @allowed_sort_fields [:id, :name, :description, :inserted_at, :updated_at]

  def index(conn, params) do
    # Parse pagination params (page, per_page, filters)
    pagination_opts = parse_pagination_params(params, filter_keys: [:search])

    # Parse sorting params separately
    sort_by = parse_sort_field(params["sort_by"], :name, @allowed_sort_fields)
    sort_order = parse_sort_order(params["sort_order"], :asc)

    # Combine pagination and sorting options
    opts =
      Keyword.merge(pagination_opts, [
        sort_by: sort_by,
        sort_order: sort_order
      ])

    # Get roles with pagination and sorting
    pagination = Roles.list_roles(opts)

    conn
    |> assign(:active_nav, :administration)
    |> assign(:sort_by, sort_by)
    |> assign(:sort_order, sort_order)
    |> assign(Pagination.to_assigns(pagination, :roles))
    |> render(:index)
  end
end
