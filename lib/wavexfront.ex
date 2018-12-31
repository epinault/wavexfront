defmodule Wavexfront do
  @moduledoc """
  This guide provide the necessary to configure and use the Wavexfront and start monitoring your application

  ## Configuration

  The ```:wavefront``` application needs to be configured properly in order to work.
  This configuration can be done, for example, in ```config/config.exs```:

  ```elixir
  config :wavexfront,
    enabled: true,
    histogram_1m: [
      enabled: true,
      host: "myhost.com"
    ]
  ```

  This would enabled wavexfront and start a connection pool for the 1 minute histogram support. This will also
  send the metrics to "myhost.com" on default port 40001

  * ```:enabled``` - Enable sending metrics to Wavefront proxy. If set to ```false``` it is not even attempting to send them.
    If value is set to ```:log```, metrics will be showing in the logs. If set to ```true```, metrics will attempt to forward to the
    the correct connection pool and proxy configured based on the type of metric sent. Default values is ```false```.
  * One or many configuration for each pool.

  This library is quite configurable so you can decide where to send the metrics and how
  much concurrency you want for it (using pool connection)

  There are currently 4 connection pools supported:

    * ```histogram_1m```: for Minute histograms metrics
    * ```histogram_1h```: for Hourly histograms metrics
    * ```histogram_1d```: for daily histograms metrics
    * ```counter_and_gauge```: for counter and gauge metrics


  Each connection pool has its own set of configuration. The following options are available

  * ```:enabled``` - Wether to enable this connection pool or not. When false, the connection pool will not be started

  * ```:host``` - The host to send the metrics too. Default to **localhost**

  * ```:port``` - The port to connect to. Defaults are:
    * for histogram_1m: 40001
    * for histogram_1h: 40002
    * for histogram_1d: 40003
    * for counter_and_gauge: 2878

  * ```:timeout``` - Connection timeout

  * ```:pool_size``` - Number of connection in the pool


  ## Sending metrics

  In order to send metrics, a simple API exists. Currently we do not support storing locally metrics and then then send the data to the proxy.
  We expect the proxy to store histogram or counter value and take care of it. Which means need to talk to the same proxy.

  For counter, you will need to store yourself the counter (in process, state or :ets table) if you decide to use them

  Here is how you would send an histogram value

  ```elixir
  Wavexfront.send_histogram("my_histo", value: 2, source: "my_host", labels: [name: :value])
  ```

  """

  use Application

  def start(_type, _args) do
    children = [{Wavexfront.Client, client_config()}]

    children =
      case wavexfront_enabled?() do
        true ->
          children
          |> start_histogram_pool(:histogram_1m)
          |> start_histogram_pool(:histogram_1h)
          |> start_histogram_pool(:histogram_1d)
          |> start_counter_and_gauge_pool

        _ ->
          children
      end

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def send_metric(name, details, client \\ Wavexfront.Client) do
    final_details = details |> Keyword.put(:name, name)

    item = Wavexfront.Item.new(final_details)
    client.emit(item)
  end

  def send_histogram(name, details, client \\ Wavexfront.Client) do
    {interval, final_details} = Keyword.pop(details, :interval, :one_minute)

    send_metric(name, final_details |> Keyword.put(:type, histogram_type_for(interval)), client)
  end

  def histogram_type_for(:one_minute = _interval), do: :histogram_1m
  def histogram_type_for(:one_hour = _interval), do: :histogram_1h
  def histogram_type_for(:one_day = _interval), do: :histogram_1d

  def send_gauge(name, details, client \\ Wavexfront.Client) do
    send_metric(name, details |> Keyword.put(:type, :gauge), client)
  end

  def send_counter(name, details, client \\ Wavexfront.Client) do
    send_metric(name, details |> Keyword.put(:type, :counter), client)
  end

  def send_delta_counter(name, details, client \\ Wavexfront.Client) do
    final_details =
      details
      |> Keyword.put(:type, :counter)
      |> Keyword.put(:delta, true)

    send_metric(name, final_details, client)
  end

  def wavexfront_enabled?() do
    Application.get_env(:wavexfront, :enabled, false)
  end

  def histogram_enabled?(timerange) do
    case Application.get_env(:wavexfront, timerange) do
      nil ->
        false

      config ->
        Keyword.get(config, :enabled, false)
    end
  end

  def counter_and_gauge_enabled? do
    case Application.get_env(:wavexfront, :counter_and_gauge) do
      nil ->
        false

      config ->
        Keyword.get(config, :enabled, false)
    end
  end

  defp start_histogram_pool(children, timerange) do
    if histogram_enabled?(timerange) do
      children ++ connection_pool_spec(timerange)
    else
      children
    end
  end

  defp start_counter_and_gauge_pool(children) do
    if counter_and_gauge_enabled?() do
      children ++ connection_pool_spec(:counter_and_gauge)
    else
      children
    end
  end

  def connection_pool_spec(name) do
    [
      :poolboy.child_spec(
        name,
        poolboy_config(name),
        worker_config(name)
      )
    ]
  end

  def client_config() do
    env = Application.get_all_env(:wavexfront)

    env
    |> Keyword.take([:enabled])
  end

  defp poolboy_config(name) do
    [
      {:name, {:local, name}},
      {:worker_module, Wavexfront.Proxy.Worker},
      {:size, pool_size_config(name)},
      {:max_overflow, 1}
    ]
  end

  def pool_size_config(name) do
    case Application.get_env(:wavexfront, name) do
      nil ->
        2

      config ->
        Keyword.get(config, :pool_size, 2)
    end
  end

  def worker_config(name) do
    default_config_parse(name)
  end

  def default_config_parse(name) do
    config = Application.get_env(:wavexfront, name, [])

    [
      host: Keyword.get(config, :host, "localhost"),
      port: Keyword.get(config, :port, default_port(name)),
      timeout: Keyword.get(config, :timeout, 5000)
    ]
  end

  def default_port(:histogram_1m = _name), do: 40_001
  def default_port(:histogram_1h = _name), do: 40_002
  def default_port(:histogram_1d = _name), do: 40_003
  def default_port(:counter_and_gauge = _name), do: 2878
end
