defmodule TimelessDashboard.DefaultMetrics do
  @moduledoc """
  Pre-built `Telemetry.Metrics` definitions for common BEAM/Phoenix/Ecto events.

  These return standard `Telemetry.Metrics` structs — you can mix them with
  your own custom metrics when configuring the reporter.

  ## Example

      metrics =
        TimelessDashboard.DefaultMetrics.vm_metrics() ++
        TimelessDashboard.DefaultMetrics.phoenix_metrics() ++
        TimelessDashboard.DefaultMetrics.ecto_metrics("my_app.repo")

      {TimelessDashboard, store: :metrics, metrics: metrics}
  """

  import Telemetry.Metrics

  @doc """
  VM metrics emitted by `:telemetry_poller`.

  Requires `{:telemetry_poller, "~> 1.0"}` in your deps and the default
  poller running (it starts automatically).

  Captures memory (total, processes, binary, atom, ets), run queue lengths,
  and system counts (processes, atoms, ports).
  """
  def vm_metrics do
    [
      # Memory
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.memory.processes_used", unit: :byte),
      last_value("vm.memory.binary", unit: :byte),
      last_value("vm.memory.atom", unit: :byte),
      last_value("vm.memory.ets", unit: :byte),

      # Run queues
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io"),

      # System counts
      last_value("vm.system_counts.process_count"),
      last_value("vm.system_counts.atom_count"),
      last_value("vm.system_counts.port_count")
    ]
  end

  @doc """
  Phoenix endpoint and router metrics.

  Captures request duration and count, tagged by method, route, and status.
  """
  def phoenix_metrics do
    [
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond},
        tags: [:method, :status],
        tag_values: &phoenix_tag_values/1
      ),
      counter("phoenix.endpoint.stop.duration",
        tags: [:method, :status],
        tag_values: &phoenix_tag_values/1
      ),
      summary("phoenix.router_dispatch.stop.duration",
        unit: {:native, :millisecond},
        tags: [:method, :route, :status],
        tag_values: &phoenix_router_tag_values/1
      ),
      counter("phoenix.router_dispatch.stop.duration",
        tags: [:method, :route, :status],
        tag_values: &phoenix_router_tag_values/1
      )
    ]
  end

  @doc """
  Ecto repo metrics.

  Takes the repo event prefix as a string (e.g., `"my_app.repo"`).
  Captures query total_time and queue_time, tagged by source table.
  """
  def ecto_metrics(repo_prefix) do
    event_prefix =
      repo_prefix
      |> String.split(".")
      |> Enum.map(&String.to_atom/1)

    [
      summary(event_prefix ++ [:query, :total_time],
        unit: {:native, :millisecond},
        tags: [:source],
        tag_values: &ecto_tag_values/1
      ),
      counter(event_prefix ++ [:query, :total_time],
        tags: [:source],
        tag_values: &ecto_tag_values/1
      ),
      summary(event_prefix ++ [:query, :queue_time],
        unit: {:native, :millisecond},
        tags: [:source],
        tag_values: &ecto_tag_values/1
      )
    ]
  end

  @doc """
  Phoenix LiveView metrics.

  Captures mount and handle_event durations, tagged by view module and event.
  """
  def live_view_metrics do
    [
      summary("phoenix.live_view.mount.stop.duration",
        unit: {:native, :millisecond},
        tags: [:view],
        tag_values: &live_view_mount_tag_values/1
      ),
      summary("phoenix.live_view.handle_event.stop.duration",
        unit: {:native, :millisecond},
        tags: [:view, :event],
        tag_values: &live_view_event_tag_values/1
      )
    ]
  end

  # --- Tag value extractors ---

  defp phoenix_tag_values(%{conn: conn}) do
    %{
      method: conn.method,
      status: conn.status
    }
  end

  defp phoenix_tag_values(metadata), do: metadata

  defp phoenix_router_tag_values(%{conn: conn, route: route}) do
    %{
      method: conn.method,
      route: route,
      status: conn.status
    }
  end

  defp phoenix_router_tag_values(%{conn: conn}) do
    %{
      method: conn.method,
      route: conn.request_path,
      status: conn.status
    }
  end

  defp phoenix_router_tag_values(metadata), do: metadata

  defp ecto_tag_values(%{source: source}) when is_binary(source), do: %{source: source}
  defp ecto_tag_values(_metadata), do: %{source: "unknown"}

  defp live_view_mount_tag_values(%{socket: socket}) do
    %{view: inspect(socket.view)}
  end

  defp live_view_mount_tag_values(metadata), do: metadata

  defp live_view_event_tag_values(%{socket: socket, event: event}) do
    %{view: inspect(socket.view), event: event}
  end

  defp live_view_event_tag_values(metadata), do: metadata
end
