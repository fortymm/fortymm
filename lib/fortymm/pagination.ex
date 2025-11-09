defmodule Fortymm.Pagination do
  @moduledoc """
  Shared pagination data structure and helpers.

  This module provides a consistent pagination interface across the application,
  including data structures, query helpers, and metadata calculations.
  """

  @type t :: %__MODULE__{
          entries: list(),
          page: pos_integer(),
          per_page: pos_integer(),
          total_entries: non_neg_integer(),
          total_pages: pos_integer(),
          filters: map()
        }

  defstruct entries: [],
            page: 1,
            per_page: 20,
            total_entries: 0,
            total_pages: 1,
            filters: %{}

  @doc """
  Creates a new pagination struct from query results.

  ## Parameters

    * `entries` - The list of items for the current page
    * `opts` - Options keyword list with:
      * `:page` - Current page number (default: 1)
      * `:per_page` - Items per page (default: 20)
      * `:total_entries` - Total number of entries across all pages
      * `:filters` - Map of additional filter parameters (default: %{})

  ## Examples

      iex> Pagination.new(users, page: 1, per_page: 20, total_entries: 100)
      %Pagination{entries: [...], page: 1, per_page: 20, total_entries: 100, total_pages: 5}

  """
  def new(entries, opts \\ []) do
    page = max(Keyword.get(opts, :page, 1), 1)
    per_page = max(Keyword.get(opts, :per_page, 20), 1)
    total_entries = Keyword.get(opts, :total_entries, length(entries))
    total_pages = max(ceil(total_entries / per_page), 1)
    filters = Keyword.get(opts, :filters, %{})

    %__MODULE__{
      entries: entries,
      page: page,
      per_page: per_page,
      total_entries: total_entries,
      total_pages: total_pages,
      filters: filters
    }
  end

  @doc """
  Applies pagination to an Ecto query.

  ## Examples

      query = from u in User
      pagination = Pagination.new([], page: 2, per_page: 20)
      Pagination.apply_to_query(query, pagination)
      # => query with limit and offset applied

  """
  def apply_to_query(query, %__MODULE__{page: page, per_page: per_page}) do
    import Ecto.Query

    query
    |> limit(^per_page)
    |> offset(^((page - 1) * per_page))
  end

  @doc """
  Returns true if there is a previous page.
  """
  def has_previous?(%__MODULE__{page: page}), do: page > 1

  @doc """
  Returns true if there is a next page.
  """
  def has_next?(%__MODULE__{page: page, total_pages: total_pages}), do: page < total_pages

  @doc """
  Returns the range of page numbers to display in pagination UI.

  Displays up to 5 page numbers, centered around the current page.

  ## Examples

      iex> Pagination.page_range(%Pagination{page: 1, total_pages: 10})
      1..5

      iex> Pagination.page_range(%Pagination{page: 5, total_pages: 10})
      3..7

      iex> Pagination.page_range(%Pagination{page: 10, total_pages: 10})
      6..10

  """
  def page_range(%__MODULE__{page: current_page, total_pages: total_pages}) do
    # Show 5 pages at a time, centered on current page
    half_window = 2
    start_page = max(1, current_page - half_window)
    end_page = min(total_pages, start_page + 4)

    # Adjust start if we're near the end
    start_page = max(1, min(start_page, end_page - 4))

    start_page..end_page
  end

  @doc """
  Returns a summary string like "Showing 1 to 20 of 100 results".
  """
  def summary(%__MODULE__{page: page, per_page: per_page, total_entries: total}) do
    start = (page - 1) * per_page + 1
    end_item = min(page * per_page, total)

    "Showing #{start} to #{end_item} of #{total} results"
  end

  @doc """
  Converts pagination struct to a map suitable for template assigns.

  ## Examples

      iex> pagination = Pagination.new(users, page: 1, per_page: 20, total_entries: 100)
      iex> Pagination.to_assigns(pagination, :users)
      %{
        users: [...],
        pagination: %Pagination{...},
        page: 1,
        per_page: 20,
        total_entries: 100,
        total_pages: 5
      }

  """
  def to_assigns(%__MODULE__{} = pagination, entries_key) do
    %{
      entries_key => pagination.entries,
      pagination: pagination,
      page: pagination.page,
      per_page: pagination.per_page,
      total_entries: pagination.total_entries,
      total_pages: pagination.total_pages
    }
    |> Map.merge(pagination.filters)
  end
end
