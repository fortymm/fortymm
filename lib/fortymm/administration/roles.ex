defmodule Fortymm.Administration.Roles do
  @moduledoc """
  The Roles context for administration.
  Provides functions for listing, filtering, sorting, and managing roles.
  """

  import Ecto.Query, warn: false
  alias Fortymm.Accounts.Role
  alias Fortymm.Pagination
  alias Fortymm.Repo

  @doc """
  Lists roles with optional filtering, sorting, and pagination.

  ## Options

    * `:page` - The page number (defaults to 1)
    * `:per_page` - Number of items per page (defaults to 20)
    * `:sort_by` - Field to sort by (defaults to :name)
    * `:sort_order` - Sort order, either :asc or :desc (defaults to :asc)
    * `:filters` - Map of filter parameters (search, etc.)

  ## Examples

      iex> list_roles()
      %Pagination{entries: [...], total_entries: 10, page: 1, per_page: 20, total_pages: 1}

      iex> list_roles(filters: %{search: "admin"}, sort_by: :name)
      %Pagination{entries: [...], total_entries: 2, page: 1, per_page: 20, total_pages: 1}

  """
  def list_roles(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    sort_by = Keyword.get(opts, :sort_by, :name)
    sort_order = Keyword.get(opts, :sort_order, :asc)
    filters = Keyword.get(opts, :filters, %{})

    search = Map.get(filters, :search)

    query =
      Role
      |> preload(:permissions)
      |> apply_search_filter(search)
      |> apply_sort(sort_by, sort_order)

    total_entries = Repo.aggregate(query, :count)

    # Create pagination struct with pagination options only
    pagination = Pagination.new([], page: page, per_page: per_page, filters: filters)

    roles =
      query
      |> Pagination.apply_to_query(pagination)
      |> Repo.all()

    # Load user counts for each role
    roles_with_counts = load_user_counts(roles)

    Pagination.new(roles_with_counts,
      page: page,
      per_page: per_page,
      total_entries: total_entries,
      filters: filters
    )
  end

  @doc """
  Gets a single role by ID.

  Returns nil if the role does not exist.

  ## Examples

      iex> get_role(123)
      %Role{}

      iex> get_role(456)
      nil

  """
  def get_role(id) do
    Role
    |> preload(:permissions)
    |> Repo.get(id)
  end

  @doc """
  Gets a single role by ID, raising an error if not found.

  ## Examples

      iex> get_role!(123)
      %Role{}

      iex> get_role!(456)
      ** (Ecto.NoResultsError)

  """
  def get_role!(id) do
    Role
    |> preload(:permissions)
    |> Repo.get!(id)
  end

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search) when is_binary(search) do
    search_pattern = "%#{search}%"

    where(
      query,
      [r],
      ilike(r.name, ^search_pattern) or ilike(r.description, ^search_pattern)
    )
  end

  defp apply_sort(query, sort_by, sort_order)
       when sort_by in [:id, :name, :description, :inserted_at, :updated_at] and
              sort_order in [:asc, :desc] do
    order_by(query, [r], [{^sort_order, field(r, ^sort_by)}])
  end

  defp apply_sort(query, _sort_by, _sort_order) do
    order_by(query, [r], asc: r.name)
  end

  defp load_user_counts(roles) do
    role_ids = Enum.map(roles, & &1.id)

    counts_query =
      from u in Fortymm.Administration.Users.User,
        where: u.role_id in ^role_ids,
        group_by: u.role_id,
        select: {u.role_id, count(u.id)}

    counts = Repo.all(counts_query) |> Map.new()

    Enum.map(roles, fn role ->
      role
      |> Map.from_struct()
      |> Map.put(:user_count, Map.get(counts, role.id, 0))
    end)
  end
end
