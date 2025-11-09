defmodule FortymmWeb.Administration.UserController do
  use FortymmWeb, :controller

  import FortymmWeb.PaginationHelpers

  alias Fortymm.Administration.Users
  alias Fortymm.Pagination

  plug FortymmWeb.Plugs.RequirePermission, "access_administration"

  @allowed_sort_fields [:id, :email, :username, :inserted_at, :updated_at, :confirmed_at]

  def index(conn, params) do
    # Parse pagination params (page, per_page, filters)
    pagination_opts = parse_pagination_params(params, filter_keys: [:search, :role_id])

    # Parse sorting params separately
    sort_by = parse_sort_field(params["sort_by"], :inserted_at, @allowed_sort_fields)
    sort_order = parse_sort_order(params["sort_order"], :desc)

    # Combine pagination and sorting options
    opts =
      Keyword.merge(pagination_opts, [
        sort_by: sort_by,
        sort_order: sort_order
      ])

    # Get users with pagination and sorting
    pagination = Users.list_users(opts)

    # Get roles for filter dropdown
    roles = Users.list_roles()

    conn
    |> assign(:active_nav, :administration)
    |> assign(:roles, roles)
    |> assign(:sort_by, sort_by)
    |> assign(:sort_order, sort_order)
    |> assign(Pagination.to_assigns(pagination, :users))
    |> render(:index)
  end
end
