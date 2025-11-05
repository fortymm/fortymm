defmodule FortymmWeb.ChallengeLive.WaitingRoom do
  use FortymmWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto">
        <div class="card bg-base-200 shadow-xl">
          <div class="card-body items-center text-center">
            <%!-- Animated waiting indicator --%>
            <div class="relative w-32 h-32 mb-6">
              <div class="absolute inset-0 rounded-full border-8 border-primary/20"></div>
              <div class="absolute inset-0 rounded-full border-8 border-primary border-t-transparent animate-spin">
              </div>
              <div class="absolute inset-0 flex items-center justify-center">
                <.icon name="hero-trophy" class="size-16 text-primary" />
              </div>
            </div>

            <h2 class="card-title text-3xl mb-2">Waiting for Opponent</h2>
            <p class="text-lg opacity-75 mb-6">
              Challenge sent! We're waiting for your opponent to accept.
            </p>

            <%!-- Challenge Details --%>
            <div class="w-full max-w-md space-y-4 mb-6">
              <div class="flex justify-between items-center p-4 bg-base-100 rounded-lg">
                <span class="font-semibold">Challenge ID:</span>
                <span class="font-mono text-primary">#{@challenge_id}</span>
              </div>

              <div class="flex justify-between items-center p-4 bg-base-100 rounded-lg">
                <span class="font-semibold">Opponent:</span>
                <span>Waiting...</span>
              </div>

              <div class="flex justify-between items-center p-4 bg-base-100 rounded-lg">
                <span class="font-semibold">Challenge Type:</span>
                <span>Quick Match</span>
              </div>
            </div>

            <%!-- Actions --%>
            <div class="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
              <.link href={~p"/dashboard"} class="btn btn-outline">
                <.icon name="hero-arrow-left" class="size-5" /> Back to Dashboard
              </.link>
              <button class="btn btn-error btn-outline" phx-click="cancel_challenge">
                <.icon name="hero-x-mark" class="size-5" /> Cancel Challenge
              </button>
            </div>
          </div>
        </div>

        <%!-- Info Alert --%>
        <div class="alert bg-info/10 border-info/20 mt-6">
          <.icon name="hero-information-circle" class="size-6 text-info" />
          <div>
            <div class="font-bold">Heads up!</div>
            <div class="text-sm opacity-75">
              Your opponent will receive a notification. You'll be automatically redirected when they accept.
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    socket =
      socket
      |> assign(:challenge_id, id)

    {:ok, socket}
  end

  @impl true
  def handle_event("cancel_challenge", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Challenge cancelled")
     |> push_navigate(to: ~p"/dashboard")}
  end
end
