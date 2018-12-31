# Wavexfront

Elixir client for [Wavefront](https://docs.wavefront.com/wavefront_data_format.html)

Specification of the format can be found [here](https://docs.wavefront.com/wavefront_data_format.html)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `wavexfront` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wavexfront, "~> 0.1.0"}
  ]
end
```

Then run mix deps.get in your shell to fetch the dependencies.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/wavexfront](https://hexdocs.pm/wavexfront).

You can also generate the documentation locally with

```
mix docs
```

Then open the _doc/index.html_ generated

## Usage

Wavefront requires some configuration in order to work. For example, in config/config.exs:

```elixir
config :wavexfront,
  enabled: true,
  histogram_1m: [enabled: true],
  counter_and_gauge: [enabled: true]

```

For detailed information on configuration and usage, take a look at the online documentation.

Now in order to send a metric you can use the following API

- Histogram

```elixir
  Wavexfront.send_histogram("my_histogram", value: 42, source: "myhost", labels: [yo: "mama"])
```

- Counter

```elixir
  Wavexfront.send_counter("my_counter", source: "myhost", labels: [yo: "mama"])

  # or  Delta counter (if you do not maintain the counter yourself)

  Wavexfront.send_delta_counter("my_counter", source: "myhost", labels: [yo: "mama"])
```

- Gauge

```elixir
  Wavexfront.send_gauge("my_gauge", value: 2, source: "myhost", labels: [yo: "mama"])
```

## Contributing

To run tests, run:

```
mix test
```

Also make sure to run the following to check that there are no warning/error reported by credo. So you will want to run:

```
mix credo
```

Also make sure your code is formatted using the elixir formatter

```
mix format
```

Finally, thanks for contributing! :)

## License

This software is licensed under Apache License 2.0
