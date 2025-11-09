defmodule Fortymm.Administration.Users do
  @moduledoc """
  The Users context for administration.
  Provides functions for listing, filtering, sorting, and managing users.
  """

  import Ecto.Query, warn: false
  alias Fortymm.Accounts.Role
  alias Fortymm.Administration.Users.User
  alias Fortymm.Pagination
  alias Fortymm.Repo

  @doc """
  Lists users with optional filtering, sorting, and pagination.

  ## Options

    * `:page` - The page number (defaults to 1)
    * `:per_page` - Number of items per page (defaults to 20)
    * `:sort_by` - Field to sort by (defaults to :inserted_at)
    * `:sort_order` - Sort order, either :asc or :desc (defaults to :desc)
    * `:filters` - Map of filter parameters (search, role_id, etc.)

  ## Examples

      iex> list_users()
      %Pagination{entries: [...], total_entries: 100, page: 1, per_page: 20, total_pages: 5}

      iex> list_users(filters: %{search: "john"}, sort_by: :email)
      %Pagination{entries: [...], total_entries: 5, page: 1, per_page: 20, total_pages: 1}

  """
  def list_users(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    sort_by = Keyword.get(opts, :sort_by, :inserted_at)
    sort_order = Keyword.get(opts, :sort_order, :desc)
    filters = Keyword.get(opts, :filters, %{})

    search = Map.get(filters, :search)
    role_id = Map.get(filters, :role_id)

    query =
      User
      |> preload(:role)
      |> apply_search_filter(search)
      |> apply_role_filter(role_id)
      |> apply_sort(sort_by, sort_order)

    total_entries = Repo.aggregate(query, :count)

    # Create pagination struct with pagination options only
    pagination = Pagination.new([], page: page, per_page: per_page, filters: filters)

    users =
      query
      |> Pagination.apply_to_query(pagination)
      |> Repo.all()

    Pagination.new(users,
      page: page,
      per_page: per_page,
      total_entries: total_entries,
      filters: filters
    )
  end

  @doc """
  Gets a single user by ID.

  Returns nil if the user does not exist.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  def get_user(id) do
    User
    |> preload(:role)
    |> Repo.get(id)
  end

  @doc """
  Gets a single user by ID, raising an error if not found.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    User
    |> preload(:role)
    |> Repo.get!(id)
  end

  @doc """
  Gets a list of all roles for filtering.

  ## Examples

      iex> list_roles()
      [%Role{}, ...]

  """
  def list_roles do
    Role
    |> order_by(:name)
    |> Repo.all()
  end

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search) when is_binary(search) do
    search_pattern = "%#{search}%"

    where(
      query,
      [u],
      ilike(u.email, ^search_pattern) or ilike(u.username, ^search_pattern)
    )
  end

  defp apply_role_filter(query, nil), do: query
  defp apply_role_filter(query, ""), do: query

  defp apply_role_filter(query, role_id) when is_integer(role_id) do
    where(query, [u], u.role_id == ^role_id)
  end

  defp apply_role_filter(query, role_id) when is_binary(role_id) do
    case Integer.parse(role_id) do
      {id, ""} -> where(query, [u], u.role_id == ^id)
      _ -> query
    end
  end

  defp apply_sort(query, sort_by, sort_order)
       when sort_by in [:id, :email, :username, :inserted_at, :updated_at, :confirmed_at] and
              sort_order in [:asc, :desc] do
    order_by(query, [u], [{^sort_order, field(u, ^sort_by)}])
  end

  defp apply_sort(query, _sort_by, _sort_order) do
    order_by(query, [u], desc: u.inserted_at)
  end
end
