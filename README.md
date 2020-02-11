# RasaSdk

API of the action server which is used by Rasa to execute custom actions.

### Building

To install the required dependencies and to build the elixir project, run:
```
mix local.hex --force
mix do deps.get, compile
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rasa_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:rasa_sdk, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/rasa_sdk](https://hexdocs.pm/rasa_sdk).
