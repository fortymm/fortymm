defmodule Fortymm.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime
      add :username, :text, null: false

      timestamps(type: :utc_datetime)
    end

    execute(
      """
      ALTER TABLE users ADD COLUMN normalized_username TEXT
        GENERATED ALWAYS AS (lower(username)) STORED
      """,
      "ALTER TABLE users DROP COLUMN normalized_username"
    )

    execute(
      """
      ALTER TABLE users ADD CONSTRAINT username_format_chk
      CHECK (
        username ~ '^(?=.{3,20}$)(?!.*[_.]{2})[a-zA-Z0-9](?:[a-zA-Z0-9._]*[a-zA-Z0-9])$'
      )
      """,
      "ALTER TABLE users DROP CONSTRAINT username_format_chk"
    )

    create unique_index(:users, [:email])
    create unique_index(:users, [:normalized_username], name: :users_normalized_username_uidx)

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
