defmodule FortymmWeb.Components.Gravatar do
  @moduledoc """
  Gravatar component for displaying user avatars.
  """
  use Phoenix.Component

  @doc """
  Renders a gravatar image based on the user's email address.

  ## Examples

      <Gravatar.avatar email={@user.email} />
      <Gravatar.avatar email={@user.email} size={40} class="rounded-full" />
  """
  attr :email, :string, required: true
  attr :size, :integer, default: 80
  attr :class, :string, default: nil
  attr :alt, :string, default: "User avatar"
  attr :rest, :global

  def avatar(assigns) do
    hash =
      assigns.email
      |> String.trim()
      |> String.downcase()
      |> then(&:crypto.hash(:md5, &1))
      |> Base.encode16(case: :lower)

    assigns = assign(assigns, :hash, hash)

    ~H"""
    <img
      src={"https://www.gravatar.com/avatar/#{@hash}?s=#{@size}&d=identicon"}
      alt={@alt}
      class={@class}
      {@rest}
    />
    """
  end
end
