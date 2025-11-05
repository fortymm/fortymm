defmodule FortymmWeb.DashboardLive do
  use FortymmWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto">
        <.header>
          Dashboard
          <:subtitle>Welcome back, {@current_scope.user.username}! 👋</:subtitle>
        </.header>

        <div class="mt-8 grid gap-6">
          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              <h2 class="card-title text-2xl">🚀 Coming Soon!</h2>
              <p class="text-lg">
                We're cooking up something special just for you. Your dashboard will soon be filled with amazing features that'll make your life easier.
              </p>
            </div>
          </div>

          <div class="grid md:grid-cols-3 gap-4">
            <div class="card bg-base-200 shadow-md hover:shadow-xl transition-shadow">
              <div class="card-body">
                <h3 class="card-title text-lg">📊 Analytics</h3>
                <p class="text-sm opacity-75">
                  Track your progress with beautiful charts and insights.
                </p>
              </div>
            </div>

            <div class="card bg-base-200 shadow-md hover:shadow-xl transition-shadow">
              <div class="card-body">
                <h3 class="card-title text-lg">⚡ Quick Actions</h3>
                <p class="text-sm opacity-75">Get things done faster with one-click shortcuts.</p>
              </div>
            </div>

            <div class="card bg-base-200 shadow-md hover:shadow-xl transition-shadow">
              <div class="card-body">
                <h3 class="card-title text-lg">🎯 Personalized</h3>
                <p class="text-sm opacity-75">Everything tailored to your unique workflow.</p>
              </div>
            </div>
          </div>

          <div class="alert bg-primary/10 border-primary/20">
            <div>
              <span class="text-lg">✨</span>
              <span>
                <div class="font-bold">Stay tuned!</div>
                <div class="text-sm opacity-75">
                  We're working around the clock to bring you the best experience.
                </div>
              </span>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:active_nav, :dashboard)

    {:ok, socket}
  end
end
