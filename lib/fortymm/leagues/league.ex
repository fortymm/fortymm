defmodule Fortymm.Leagues.League do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @usatt_slug "usatt"

  def usatt_slug(), do: @usatt_slug

  schema "leagues" do
    field :name, :string
    field :slug, :string

    timestamps()
  end

  def with_slug(query, slug) do
    from leagues in query,
      where: leagues.slug == ^slug
  end

  @doc false
  def changeset(league, attrs) do
    league
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
  end
end
