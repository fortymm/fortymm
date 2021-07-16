defmodule Fortymm.Repo.Migrations.CreateLeagues do
  use Ecto.Migration

  def change do
    create table(:leagues) do
      add :name, :string
      add :slug, :string

      timestamps()
    end

  end
end
