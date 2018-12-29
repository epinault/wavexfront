defmodule Wavexfront.ItemTest do
  use ExUnit.Case
  doctest Wavexfront.Item

  alias Wavexfront.Item

  test "It convert to text when missing a timestamp the world" do
    item = %Item{
      type: "type",
      name: "name",
      value: "value",
      source: "source",
      labels: [label1: "yo"]
    }

    assert Item.to_text(item) == "name value source \"label1\"=\"yo\"\n"
  end

  test "It convert to text with multiple labels" do
    item = %Item{
      type: "type",
      name: "name",
      value: "value",
      source: "source",
      labels: [label1: "yo", label2: "mama"]
    }

    assert Item.to_text(item) == "name value source \"label1\"=\"yo\" \"label2\"=\"mama\"\n"
  end

  test "It convert to text when missing a labels and timestamp" do
    item = %Item{
      type: "type",
      name: "name",
      value: "value",
      source: "source",
      labels: [label1: "yo", label2: "mama"]
    }

    assert Item.to_text(item) == "name value source \"label1\"=\"yo\" \"label2\"=\"mama\"\n"
  end

  test "It convert to text with a timestamp" do
    time = DateTime.utc_now()

    item = %Item{
      type: "type",
      name: "name",
      value: "value",
      source: "source",
      timestamp: time,
      labels: [label1: "yo", label2: "mama"]
    }

    assert Item.to_text(item) ==
             "name value #{DateTime.to_unix(time)} source \"label1\"=\"yo\" \"label2\"=\"mama\"\n"
  end
end
