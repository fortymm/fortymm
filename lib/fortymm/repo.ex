defmodule Fortymm.Repo do
  use Ecto.Repo,
    otp_app: :fortymm,
    adapter: Ecto.Adapters.Postgres
end
