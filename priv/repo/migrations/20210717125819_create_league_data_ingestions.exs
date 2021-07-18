defmodule Fortymm.Repo.Migrations.CreateLeagueDataIngestions do
  use Ecto.Migration

  def change do
    create table(:league_data_ingestions) do
      add :started_at, :naive_datetime
      add :completed_at, :naive_datetime
      add :status, :string
      add :league_id, references(:leagues, on_delete: :nothing)

      timestamps()
    end

    create index(:league_data_ingestions, [:league_id])
  end
end
