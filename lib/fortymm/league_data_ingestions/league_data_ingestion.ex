defmodule Fortymm.LeagueDataIngestions.LeagueDataIngestion do
  use Ecto.Schema
  import Ecto.Changeset

  @pending "pending"
  @in_progress "in-progress"
  @completed "completed"
  @failed "failed"

  def pending, do: @pending
  def in_progress, do: @in_progress
  def completed, do: @completed
  def failed, do: @failed

  schema "league_data_ingestions" do
    field :completed_at, :naive_datetime
    field :started_at, :naive_datetime
    field :status, :string

    timestamps()
  end

  @valid_statuses [
    @pending,
    @in_progress,
    @completed,
    @failed
  ]

  @doc false
  def changeset(league_data_ingestion, attrs) do
    league_data_ingestion
    |> cast(attrs, [:started_at, :completed_at, :status])
    |> validate_required([:status])
    |> validate_inclusion(:status, @valid_statuses)
  end
end
