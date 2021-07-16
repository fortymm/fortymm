defmodule FortymmWeb.AdministrationControllerTest do
  use FortymmWeb.ConnCase

  @header_selector "#administration-header"

  test "renders the header", %{conn: conn} do
    assert "Administration" ==
             conn
             |> get(Routes.administration_landing_page_path(conn, :index))
             |> html_response(200)
             |> Floki.find(@header_selector)
             |> Floki.text()
             |> String.trim()
  end
end
