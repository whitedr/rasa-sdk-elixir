defmodule RasaSdk.Actions.Registry do
  alias RasaSdk.Actions.Context

  def register_actions(modules) do
    actions_table = get_actions_table()
    :ets.new(actions_table, [:set, :protected, :named_table])

    modules
    |> Enum.each(fn module ->
      if RasaSdk.Actions.Action in (module.module_info(:attributes)[:behaviour] || []) do
        :ets.insert(actions_table, {module.name(), module})
      end
    end)
  end

  def execute(%Context{request: %{next_action: next_action}} = context) do
    case :ets.lookup(get_actions_table(), next_action) do
      [] ->
        context
        |> Context.set_error(next_action, "action not found")

      [{_, module}] ->
        module.run(context)
    end
  end

  defp get_actions_table() do
    Application.get_env(:rasa_action, :actions_table, :rasa_actions)
  end
end
