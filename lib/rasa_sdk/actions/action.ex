defmodule RasaSdk.Actions.Action do
  alias RasaSdk.Actions.Context

  @callback name() :: String.t()
  @callback run(Context.t()) :: Context.t()

  defmacro __using__(_) do
    quote do
      @behaviour RasaSdk.Actions.Action
      import RasaSdk.Actions.Context
      import RasaSdk.Actions.Events
    end
  end
end
