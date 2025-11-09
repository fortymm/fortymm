defmodule FortymmWeb.PaginationComponents do
  @moduledoc """
  Shared pagination UI components.

  These components provide consistent pagination interfaces
  across the application.
  """

  use Phoenix.Component
  import FortymmWeb.CoreComponents

  alias Fortymm.Pagination

  @doc """
  Renders pagination controls with page numbers and navigation buttons.

  ## Attributes

    * `pagination` - Required. The Pagination struct
    * `conn` - Required. The Plug.Conn for URL building
    * `path_fn` - Required. Function to build URLs: fn(conn, params) -> string
    * `class` - Optional. Additional CSS classes for the container

  ## Examples

      <.pagination
        pagination={@pagination}
        conn={@conn}
        path_fn={&~p"/administration/users?\#{&1}"}
      />

  """
  attr :pagination, Pagination, required: true
  attr :conn, Plug.Conn, required: true
  attr :path_fn, :any, required: true
  attr :class, :string, default: nil

  def pagination(assigns) do
    ~H"""
    <div class={["mt-6 flex items-center justify-between", @class]}>
      <div class="text-sm text-gray-700">
        {Pagination.summary(@pagination)}
      </div>

      <div class="join">
        <%!-- Previous button --%>
        <.link
          navigate={build_page_url(@conn, @path_fn, @pagination, @pagination.page - 1)}
          class={[
            "join-item btn btn-sm",
            !Pagination.has_previous?(@pagination) && "btn-disabled"
          ]}
          aria-label="Previous page"
        >
          «
        </.link>

        <%!-- Page number buttons --%>
        <.link
          :for={page <- Pagination.page_range(@pagination)}
          navigate={build_page_url(@conn, @path_fn, @pagination, page)}
          class={[
            "join-item btn btn-sm",
            page == @pagination.page && "btn-active"
          ]}
        >
          {page}
        </.link>

        <%!-- Next button --%>
        <.link
          navigate={build_page_url(@conn, @path_fn, @pagination, @pagination.page + 1)}
          class={[
            "join-item btn btn-sm",
            !Pagination.has_next?(@pagination) && "btn-disabled"
          ]}
          aria-label="Next page"
        >
          »
        </.link>
      </div>
    </div>
    """
  end

  # Helper function to build URL for page navigation
  defp build_page_url(conn, path_fn, pagination, page) do
    params =
      base_params(pagination)
      |> Map.put("page", page)

    path_fn.(conn, params)
  end

  # Build base parameters map from pagination struct
  defp base_params(pagination) do
    %{
      "page" => pagination.page,
      "per_page" => pagination.per_page
    }
    |> Map.merge(stringify_filters(pagination.filters))
  end

  # Convert filter keys from atoms to strings for URL params
  defp stringify_filters(filters) do
    Enum.into(filters, %{}, fn {k, v} -> {to_string(k), v} end)
  end
end
