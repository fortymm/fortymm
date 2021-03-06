defmodule FortymmWeb.PageLiveTest do
  use FortymmWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Administration"
    assert render(page_live) =~ "Administration"
  end
end
