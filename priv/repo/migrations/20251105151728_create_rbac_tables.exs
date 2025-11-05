defmodule Fortymm.Repo.Migrations.CreateRbacTables do
  use Ecto.Migration

  def change do
    # Create roles table
    create table(:roles) do
      add :name, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name])

    # Create permissions table
    create table(:permissions) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:permissions, [:name])
    create unique_index(:permissions, [:slug])

    # Create role_permissions join table
    create table(:role_permissions, primary_key: false) do
      add :role_id, references(:roles, on_delete: :delete_all), null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false
    end

    create index(:role_permissions, [:role_id])
    create index(:role_permissions, [:permission_id])
    create unique_index(:role_permissions, [:role_id, :permission_id])

    # Add role_id to users table
    alter table(:users) do
      add :role_id, references(:roles, on_delete: :nilify_all)
    end

    create index(:users, [:role_id])
  end
end
