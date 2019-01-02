defmodule Wavexfront.ItemTest do
  use ExUnit.Case
  doctest Wavexfront.Item

  alias Wavexfront.Item

  test "it creates a new items from keywords list" do
    assert Item.new(
             type: :histogram,
             name: "name",
             value: "value",
             source: "source",
             labels: [label1: "yo"],
             delta: true
           ) == %Item{
             type: :histogram,
             name: "name",
             value: "value",
             source: "source",
             labels: [label1: "yo"],
             delta: true
           }
  end

  test "it creates a new items with a delta default to false" do
    assert Item.new(
             type: :histogram,
             name: "name",
             value: "value",
             source: "source",
             labels: [label1: "yo"]
           ) == %Item{
             type: :histogram,
             name: "name",
             value: "value",
             source: "source",
             labels: [label1: "yo"],
             delta: false
           }
  end

  test "It convert to text when missing a timestamp the world" do
    item = %Item{
      type: "type",
      name: "name",
      value: "value",
      source: "source",
      labels: [label1: "yo"]
    }

    assert Item.to_text(item) == "name value source=\"source\" \"label1\"=\"yo\"\n"
  end

  test "It convert to text with multiple labels" do
    item = %Item{
      type: "type",
      name: "name",
      value: "value",
      source: "source",
      labels: [label1: "yo", label2: "mama"]
    }

    assert Item.to_text(item) ==
             "name value source=\"source\" \"label1\"=\"yo\" \"label2\"=\"mama\"\n"
  end

  test "It convert to text when missing a labels and timestamp" do
    item = %Item{
      type: "type",
      name: "name",
      value: "value",
      source: "source",
      labels: [label1: "yo", label2: "mama"]
    }

    assert Item.to_text(item) ==
             "name value source=\"source\" \"label1\"=\"yo\" \"label2\"=\"mama\"\n"
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
             "name value #{DateTime.to_unix(time)} source=\"source\" \"label1\"=\"yo\" \"label2\"=\"mama\"\n"
  end

  test "It convert to text with a using delta" do
    time = DateTime.utc_now()

    item = %Item{
      type: "type",
      name: "name",
      value: "value",
      source: "source",
      timestamp: time,
      delta: true,
      labels: [label1: "yo", label2: "mama"]
    }

    assert Item.to_text(item) ==
             "name Δvalue #{DateTime.to_unix(time)} source=\"source\" \"label1\"=\"yo\" \"label2\"=\"mama\"\n"
  end
end
