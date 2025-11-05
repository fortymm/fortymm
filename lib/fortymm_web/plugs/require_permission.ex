defmodule FortymmWeb.Plugs.RequirePermission do
  @moduledoc """
  A plug and LiveView hook to check if the current user has a specific permission.

  ## Usage as a plug

      plug FortymmWeb.Plugs.RequirePermission, "access_administration"

  Or with multiple permissions (any):

      plug FortymmWeb.Plugs.RequirePermission, ["manage_users", "manage_roles"]

  ## Usage in LiveView

      live_session :require_administration,
        on_mount: [{FortymmWeb.Plugs.RequirePermission, "access_administration"}] do
        live "/administration", AdminLive.Dashboard, :index
      end

  """
  import Plug.Conn

  alias Fortymm.Accounts

  # Plug callbacks
  def init(opts), do: opts

  def call(conn, permission_slug) when is_binary(permission_slug) do
    check_permission_conn(conn, permission_slug)
  end

  def call(conn, permission_slugs) when is_list(permission_slugs) do
    if Enum.any?(permission_slugs, &has_permission_conn?(conn, &1)) do
      conn
    else
      handle_unauthorized_conn(conn)
    end
  end

  # LiveView on_mount callback
  def on_mount(permission_slug, _params, _session, socket) when is_binary(permission_slug) do
    check_permission_socket(socket, permission_slug)
  end

  def on_mount(permission_slugs, _params, _session, socket) when is_list(permission_slugs) do
    if Enum.any?(permission_slugs, &has_permission_socket?(socket, &1)) do
      {:cont, socket}
    else
      handle_unauthorized_socket(socket)
    end
  end

  # Plug helpers
  defp check_permission_conn(conn, permission_slug) do
    if has_permission_conn?(conn, permission_slug) do
      conn
    else
      handle_unauthorized_conn(conn)
    end
  end

  defp has_permission_conn?(conn, permission_slug) do
    case conn.assigns[:current_scope] do
      %{user: user} when not is_nil(user) ->
        Accounts.has_permission?(user, permission_slug)

      _ ->
        false
    end
  end

  defp handle_unauthorized_conn(conn) do
    conn
    |> Phoenix.Controller.put_flash(:error, "You don't have permission to access this page.")
    |> Phoenix.Controller.redirect(to: "/dashboard")
    |> halt()
  end

  # LiveView helpers
  defp check_permission_socket(socket, permission_slug) do
    if has_permission_socket?(socket, permission_slug) do
      {:cont, socket}
    else
      handle_unauthorized_socket(socket)
    end
  end

  defp has_permission_socket?(socket, permission_slug) do
    case socket.assigns[:current_scope] do
      %{user: user} when not is_nil(user) ->
        Accounts.has_permission?(user, permission_slug)

      _ ->
        false
    end
  end

  defp handle_unauthorized_socket(socket) do
    socket =
      socket
      |> Phoenix.LiveView.put_flash(:error, "You don't have permission to access this page.")
      |> Phoenix.LiveView.redirect(to: "/dashboard")

    {:halt, socket}
  end
end
