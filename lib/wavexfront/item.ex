defmodule Wavexfront.Item do
  @moduledoc """
  This is the representation of metric item as a structure

  The to_text method allows to serialize to the format readable by the proxy using
  a TCP connection
  """
  @enforce_keys [:name, :type, :value, :source]
  defstruct [:type, :name, :value, :timestamp, :source, labels: []]

  def new(type, name, value, timestamp, source, labels) do
    %__MODULE__{
      type: type,
      name: name,
      value: value,
      timestamp: timestamp,
      source: source,
      labels: labels
    }
  end

  def to_text(%__MODULE__{} = item) do
    timestamp =
      if item.timestamp do
        DateTime.to_unix(item.timestamp)
      end

    elements = [
      item.name,
      item.value,
      timestamp,
      item.source,
      flatten_labels(item)
    ]

    Enum.join(Enum.filter(elements, &(!is_nil(&1))), " ") <> "\n"
  end

  defp flatten_labels(%__MODULE__{} = item) do
    Enum.join(
      Enum.map(item.labels, fn {key, value} ->
        "\"#{key}\"=\"#{value}\""
      end),
      " "
    )
  end
end
