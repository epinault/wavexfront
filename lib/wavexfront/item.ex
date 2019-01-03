defmodule Wavexfront.Item do
  @moduledoc """
  This is the representation of metric item as a structure

  * ```name```: The name of your metric
  * ```type```: The type of metric. Must be one of :histogram_1m, histogram_1h, histogram_1d, :counter or :gauge
  * ```timestamp```: The timestamp of the metrics. May be nil and will be then resolved by the proxy
  * ```source```: The host it was sent from
  * ```labels```: Keyword list of extra labels
  * ```delta```: Only applies to counters if they are delta counters

  The serialization of the metrics is done by using the ```Item.to_text``` function.

  """
  @enforce_keys [:name, :type, :value, :source]
  defstruct [:type, :name, :value, :timestamp, :source, labels: [], delta: false]

  @delta_prefix "\u2206"
  @alt_delta_prefix "\u0394"

  def new(fields) do
    Kernel.struct(__MODULE__, fields)
  end

  def to_text(%__MODULE__{} = item) do
    elements = [
      convert_name(item),
      convert_value(item),
      convert_timestamp(item),
      convert_source(item),
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

  defp convert_name(%__MODULE__{delta: true} = item), do: "#{@delta_prefix}#{item.name}"
  defp convert_name(%__MODULE__{} = item), do: item.name

  defp convert_source(item), do: "source=\"#{item.source}\""

  defp convert_value(%__MODULE__{} = item), do: item.value

  defp convert_timestamp(%__MODULE__{timestamp: timestamp} = item) when not is_nil(timestamp),
    do: DateTime.to_unix(item.timestamp)

  defp convert_timestamp(_item), do: nil
end
