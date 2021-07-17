defmodule Fortymm.Repo.Migrations.CreateLeagueDataIngestions do
  use Ecto.Migration

  def change do
    create table(:league_data_ingestions) do
      add :started_at, :naive_datetime
      add :completed_at, :naive_datetime
      add :status, :string

      timestamps()
    end

  end
end
