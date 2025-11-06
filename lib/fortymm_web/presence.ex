defmodule FortymmWeb.Presence do
  @moduledoc """
  Provides presence tracking for challenges.

  Allows tracking which users are currently viewing or waiting in challenge rooms.
  """
  use Phoenix.Presence,
    otp_app: :fortymm,
    pubsub_server: Fortymm.PubSub
end
