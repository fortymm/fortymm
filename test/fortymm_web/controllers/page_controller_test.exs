defmodule FortymmWeb.PageControllerTest do
  use FortymmWeb.ConnCase

  import Fortymm.AccountsFixtures

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
  end

  test "GET / redirects to dashboard when user is logged in", %{conn: conn} do
    user = user_fixture()
    conn = conn |> log_in_user(user) |> get(~p"/")

    assert redirected_to(conn) == ~p"/dashboard"
  end
end
