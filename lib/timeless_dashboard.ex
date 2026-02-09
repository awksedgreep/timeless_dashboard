defmodule TimelessDashboard do
  @moduledoc """
  Telemetry reporter and LiveDashboard page for Timeless.

  Captures `Telemetry.Metrics` events into a Timeless store, giving you
  persistent historical metrics that survive restarts — unlike the built-in
  LiveDashboard charts which reset on every page load.

  ## Reporter (standalone — no Phoenix required)

      children = [
        {Timeless, name: :metrics, data_dir: "/var/lib/metrics"},
        {TimelessDashboard,
          store: :metrics,
          metrics:
            TimelessDashboard.DefaultMetrics.vm_metrics() ++
            TimelessDashboard.DefaultMetrics.phoenix_metrics()}
      ]

  ## LiveDashboard Page

      # In your router:
      live_dashboard "/dashboard",
        additional_pages: [timeless: {TimelessDashboard.Page, store: :metrics}]
  """

  defdelegate child_spec(opts), to: TimelessDashboard.Reporter
end
