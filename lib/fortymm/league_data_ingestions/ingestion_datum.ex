defmodule Fortymm.LeagueDataIngestions.IngestionDatum do
  use Ecto.Schema
  import Ecto.Changeset

  alias Fortymm.LeagueDataIngestions.LeagueDataIngestion

  schema "league_data_ingestions" do
    field :first_name, :string
    field :last_name, :string
    field :external_league_ref, :string
    field :ingested_at, :naive_datetime
    belongs_to :league_data_ingestion, LeagueDataIngestion

    timestamps()
  end

  @doc false
  def changeset(league_data_ingestion, attrs) do
    league_data_ingestion
    |> cast(attrs, [
      :first_name,
      :last_name,
      :external_league_ref,
      :ingested_at,
      :league_data_ingestion_id
    ])
    |> validate_required([
      :first_name,
      :last_name,
      :ingested_at,
      :league_data_ingestion_id
    ])
    |> foreign_key_constraint(:league_data_ingestion_id)
  end
end
