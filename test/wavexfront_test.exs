defmodule WavexfrontTest do
  use ExUnit.Case
  doctest Wavexfront

  alias Wavexfront.Item

  defmodule Client do
    def emit(item), do: send(self(), {:emit, item})
  end

  test "it generate an histogram metric" do
    Wavexfront.send_histogram("my_histo", [value: 2, labels: [yo: :mama]], Client)

    assert_receive(
      {:emit,
       %Item{
         type: :histogram_1m,
         delta: false,
         labels: [yo: :mama],
         name: "my_histo",
         source: nil,
         value: 2
       }}
    )
  end

  test "it generate an hourly histogram metric" do
    Wavexfront.send_histogram(
      "my_histo",
      [interval: :one_hour, value: 2, labels: [yo: :mama]],
      Client
    )

    assert_receive(
      {:emit,
       %Item{
         type: :histogram_1h,
         delta: false,
         labels: [yo: :mama],
         name: "my_histo",
         source: nil,
         value: 2
       }}
    )
  end

  test "it generate a daily histogram metric" do
    Wavexfront.send_histogram(
      "my_histo",
      [interval: :one_day, value: 2, labels: [yo: :mama]],
      Client
    )

    assert_receive(
      {:emit,
       %Item{
         type: :histogram_1d,
         delta: false,
         labels: [yo: :mama],
         name: "my_histo",
         source: nil,
         value: 2
       }}
    )
  end

  test "it generate an histogram metric with a timestamp" do
    time = DateTime.utc_now()

    Wavexfront.send_histogram(
      "my_histo",
      [value: 2, labels: [yo: :mama], timestamp: time],
      Client
    )

    assert_receive(
      {:emit,
       %Item{
         type: :histogram_1m,
         delta: false,
         labels: [yo: :mama],
         name: "my_histo",
         timestamp: time,
         source: nil,
         value: 2
       }}
    )
  end

  test "it generate a gauge metric" do
    Wavexfront.send_gauge("my_gauge", [value: 2, labels: [yo: :mama]], Client)

    assert_receive(
      {:emit,
       %Item{
         type: :gauge,
         delta: false,
         labels: [yo: :mama],
         name: "my_gauge",
         source: nil,
         value: 2
       }}
    )
  end

  test "it generate a counter metric" do
    Wavexfront.send_counter("my_counter", [value: 2, labels: [yo: :mama]], Client)

    assert_receive(
      {:emit,
       %Item{
         type: :counter,
         delta: false,
         labels: [yo: :mama],
         name: "my_counter",
         source: nil,
         value: 2
       }}
    )
  end

  test "it generate a delta counter metric" do
    Wavexfront.send_delta_counter("my_delta_counter", [value: 2, labels: [yo: :mama]], Client)

    assert_receive(
      {:emit,
       %Item{
         type: :counter,
         delta: true,
         labels: [yo: :mama],
         name: "my_delta_counter",
         source: nil,
         value: 2
       }}
    )
  end

  test "it generate a metric" do
    Wavexfront.send_metric("my_metric", [value: 2, labels: [yo: :mama]], Client)

    assert_receive(
      {:emit,
       %Item{
         type: nil,
         delta: false,
         labels: [yo: :mama],
         name: "my_metric",
         source: nil,
         value: 2
       }}
    )
  end
end
