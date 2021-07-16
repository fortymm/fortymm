defmodule FortymmWeb.Administration.LandingPageController do
  use FortymmWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
