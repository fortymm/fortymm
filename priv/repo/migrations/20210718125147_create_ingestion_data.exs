defmodule Fortymm.Repo.Migrations.CreateIngestionData do
  use Ecto.Migration

  def change do
    create table(:ingestion_data) do
      add :ingested_at, :naive_datetime
      add :first_name, :string
      add :last_name, :string
      add :external_league_ref, :string
      add :league_data_ingestion_id, references(:leagues, on_delete: :nothing)

      timestamps()
    end

    create index(:ingestion_data, [:league_data_ingestion_id])
  end
end
