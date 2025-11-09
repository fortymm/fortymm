defmodule Fortymm.Administration.Permissions do
  @moduledoc """
  The Permissions context for administration.
  Provides functions for listing, filtering, sorting, and managing permissions.
  """

  import Ecto.Query, warn: false
  alias Fortymm.Accounts.Permission
  alias Fortymm.Pagination
  alias Fortymm.Repo

  @doc """
  Lists permissions with optional filtering, sorting, and pagination.

  ## Options

    * `:page` - The page number (defaults to 1)
    * `:per_page` - Number of items per page (defaults to 20)
    * `:sort_by` - Field to sort by (defaults to :name)
    * `:sort_order` - Sort order, either :asc or :desc (defaults to :asc)
    * `:filters` - Map of filter parameters (search, etc.)

  ## Examples

      iex> list_permissions()
      %Pagination{entries: [...], total_entries: 100, page: 1, per_page: 20, total_pages: 5}

      iex> list_permissions(filters: %{search: "admin"}, sort_by: :slug)
      %Pagination{entries: [...], total_entries: 5, page: 1, per_page: 20, total_pages: 1}

  """
  def list_permissions(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    sort_by = Keyword.get(opts, :sort_by, :name)
    sort_order = Keyword.get(opts, :sort_order, :asc)
    filters = Keyword.get(opts, :filters, %{})

    search = Map.get(filters, :search)

    query =
      Permission
      |> preload(:roles)
      |> apply_search_filter(search)
      |> apply_sort(sort_by, sort_order)

    total_entries = Repo.aggregate(query, :count)

    # Create pagination struct with pagination options only
    pagination = Pagination.new([], page: page, per_page: per_page, filters: filters)

    permissions =
      query
      |> Pagination.apply_to_query(pagination)
      |> Repo.all()

    Pagination.new(permissions,
      page: page,
      per_page: per_page,
      total_entries: total_entries,
      filters: filters
    )
  end

  @doc """
  Gets a single permission by ID.

  Returns nil if the permission does not exist.

  ## Examples

      iex> get_permission(123)
      %Permission{}

      iex> get_permission(456)
      nil

  """
  def get_permission(id) do
    Permission
    |> preload(:roles)
    |> Repo.get(id)
  end

  @doc """
  Gets a single permission by ID, raising an error if not found.

  ## Examples

      iex> get_permission!(123)
      %Permission{}

      iex> get_permission!(456)
      ** (Ecto.NoResultsError)

  """
  def get_permission!(id) do
    Permission
    |> preload(:roles)
    |> Repo.get!(id)
  end

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search) when is_binary(search) do
    search_pattern = "%#{search}%"

    where(
      query,
      [p],
      ilike(p.name, ^search_pattern) or ilike(p.slug, ^search_pattern) or
        ilike(p.description, ^search_pattern)
    )
  end

  defp apply_sort(query, sort_by, sort_order)
       when sort_by in [:id, :name, :slug, :inserted_at, :updated_at] and
              sort_order in [:asc, :desc] do
    order_by(query, [p], [{^sort_order, field(p, ^sort_by)}])
  end

  defp apply_sort(query, _sort_by, _sort_order) do
    order_by(query, [p], asc: p.name)
  end
end
