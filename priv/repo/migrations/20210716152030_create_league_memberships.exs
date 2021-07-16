defmodule Fortymm.Repo.Migrations.CreateLeagueMemberships do
  use Ecto.Migration

  def change do
    create table(:league_memberships) do
      add :external_league_ref, :string
      add :league_id, references(:leagues, on_delete: :nothing)
      add :player_id, references(:players, on_delete: :nothing)

      timestamps()
    end

    create index(:league_memberships, [:league_id])
    create index(:league_memberships, [:player_id])
  end
end
