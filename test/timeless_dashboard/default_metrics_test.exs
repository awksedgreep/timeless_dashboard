defmodule TimelessDashboard.DefaultMetricsTest do
  use ExUnit.Case, async: true

  alias TimelessDashboard.DefaultMetrics

  describe "vm_metrics/0" do
    test "returns non-empty list of valid metrics" do
      metrics = DefaultMetrics.vm_metrics()
      assert is_list(metrics)
      assert length(metrics) > 0

      Enum.each(metrics, fn metric ->
        assert %{__struct__: struct} = metric
        assert struct in [
                 Telemetry.Metrics.Counter,
                 Telemetry.Metrics.Sum,
                 Telemetry.Metrics.LastValue,
                 Telemetry.Metrics.Summary,
                 Telemetry.Metrics.Distribution
               ]
      end)
    end

    test "all vm metrics are last_value type" do
      metrics = DefaultMetrics.vm_metrics()

      Enum.each(metrics, fn metric ->
        assert %Telemetry.Metrics.LastValue{} = metric
      end)
    end
  end

  describe "phoenix_metrics/0" do
    test "returns non-empty list of valid metrics" do
      metrics = DefaultMetrics.phoenix_metrics()
      assert is_list(metrics)
      assert length(metrics) > 0

      Enum.each(metrics, fn metric ->
        assert %{__struct__: struct} = metric
        assert struct in [
                 Telemetry.Metrics.Counter,
                 Telemetry.Metrics.Summary
               ]
      end)
    end
  end

  describe "ecto_metrics/1" do
    test "accepts repo prefix parameter" do
      metrics = DefaultMetrics.ecto_metrics("my_app.repo")
      assert is_list(metrics)
      assert length(metrics) > 0

      # Verify event names use the prefix
      Enum.each(metrics, fn metric ->
        assert hd(metric.event_name) == :my_app
      end)
    end

    test "works with different repo prefixes" do
      metrics = DefaultMetrics.ecto_metrics("other_app.different_repo")
      assert length(metrics) > 0

      Enum.each(metrics, fn metric ->
        assert hd(metric.event_name) == :other_app
      end)
    end
  end

  describe "live_view_metrics/0" do
    test "returns non-empty list of valid metrics" do
      metrics = DefaultMetrics.live_view_metrics()
      assert is_list(metrics)
      assert length(metrics) > 0

      Enum.each(metrics, fn metric ->
        assert %Telemetry.Metrics.Summary{} = metric
      end)
    end
  end
end
