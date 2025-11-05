defmodule FortymmWeb.AdminController do
  use FortymmWeb, :controller

  plug FortymmWeb.Plugs.RequirePermission, "access_administration"

  def dashboard(conn, _params) do
    conn
    |> assign(:active_nav, :administration)
    |> render(:dashboard)
  end
end
