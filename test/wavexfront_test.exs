defmodule WavexfrontTest do
  use ExUnit.Case
  doctest Wavexfront

  test "it generate an histogram metric" do
    assert Wavexfront.hello() == :world
  end

  test "it generate a gauge metric" do
    assert Wavexfront.hello() == :world
  end

  test "it generate a counter metric" do
    assert Wavexfront.hello() == :world
  end
end
