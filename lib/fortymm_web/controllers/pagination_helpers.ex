defmodule FortymmWeb.PaginationHelpers do
  @moduledoc """
  Shared helpers for handling pagination parameters in controllers.
  """

  @doc """
  Parses pagination parameters from request params.

  ## Parameters

    * `params` - Request parameters map
    * `opts` - Options keyword list with:
      * `:default_per_page` - Default items per page (default: 20)
      * `:filter_keys` - List of additional filter parameter keys to extract (default: [])

  ## Returns

  A keyword list with:
    * `:page` - Current page number
    * `:per_page` - Items per page
    * `:filters` - Map of additional filter parameters

  ## Examples

      iex> parse_pagination_params(params, filter_keys: [:search, :role_id])
      [
        page: 1,
        per_page: 20,
        filters: %{search: "john", role_id: "3"}
      ]

  """
  def parse_pagination_params(params, opts \\ []) do
    default_per_page = Keyword.get(opts, :default_per_page, 20)
    filter_keys = Keyword.get(opts, :filter_keys, [])

    page = parse_int(params["page"], 1)
    per_page = parse_int(params["per_page"], default_per_page)
    filters = extract_filters(params, filter_keys)

    [
      page: page,
      per_page: per_page,
      filters: filters
    ]
  end

  @doc """
  Safely parses an integer from a string parameter with a default fallback.

  ## Examples

      iex> parse_int("42", 1)
      42

      iex> parse_int("invalid", 1)
      1

      iex> parse_int(nil, 10)
      10

  """
  def parse_int(nil, default), do: default

  def parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} when int > 0 -> int
      _ -> default
    end
  end

  def parse_int(value, default) when is_integer(value) and value > 0, do: value
  def parse_int(_, default), do: default

  @doc """
  Parses and validates a sort field parameter.

  Returns the field as an atom if it's in the allowed list, otherwise returns the default.

  ## Examples

      iex> parse_sort_field("name", :id, [:id, :name, :email])
      :name

      iex> parse_sort_field("invalid", :id, [:id, :name])
      :id

      iex> parse_sort_field(nil, :email, [:id, :email])
      :email

  """
  def parse_sort_field(nil, default, _allowed_fields), do: default

  def parse_sort_field(value, default, allowed_fields) when is_binary(value) do
    atom_value = String.to_existing_atom(value)

    if atom_value in allowed_fields do
      atom_value
    else
      default
    end
  rescue
    ArgumentError -> default
  end

  def parse_sort_field(value, _default, allowed_fields) when is_atom(value) do
    if value in allowed_fields, do: value, else: hd(allowed_fields)
  end

  def parse_sort_field(_, default, _allowed_fields), do: default

  @doc """
  Parses a sort order parameter.

  Returns `:asc` or `:desc`, defaulting if invalid.

  ## Examples

      iex> parse_sort_order("asc", :desc)
      :asc

      iex> parse_sort_order("desc", :asc)
      :desc

      iex> parse_sort_order("invalid", :asc)
      :asc

      iex> parse_sort_order(nil, :desc)
      :desc

  """
  def parse_sort_order(nil, default), do: default

  def parse_sort_order(value, default) when is_binary(value) do
    case value do
      "asc" -> :asc
      "desc" -> :desc
      _ -> default
    end
  end

  def parse_sort_order(value, _default) when value in [:asc, :desc], do: value
  def parse_sort_order(_, default), do: default

  @doc """
  Extracts filter parameters from the params map.

  ## Examples

      iex> extract_filters(%{"search" => "john", "role_id" => "3", "page" => "1"}, [:search, :role_id])
      %{search: "john", role_id: "3"}

      iex> extract_filters(%{"search" => ""}, [:search])
      %{}

  """
  def extract_filters(params, filter_keys) do
    Enum.reduce(filter_keys, %{}, fn key, acc ->
      string_key = to_string(key)
      value = params[string_key]

      # Only include non-empty values
      if value && value != "" do
        Map.put(acc, key, value)
      else
        acc
      end
    end)
  end
end
