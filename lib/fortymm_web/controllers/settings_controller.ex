defmodule FortymmWeb.SettingsController do
  use FortymmWeb, :controller

  def appearance(conn, _params) do
    render(conn, :appearance, active_nav: :appearance)
  end
end
