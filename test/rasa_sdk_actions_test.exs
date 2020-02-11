defmodule RasaSdkActionsTest do
  use ExUnit.Case

  alias RasaSdk.Actions.{Action, Context, Events, FormAction}
  alias RasaSdk.Model.Tracker
  alias RasaSdk.Model.Request
  # alias RasaSdk.Model.InlineResponse200, as: Response
  alias RasaSdk.Model.ResponseRejected

  defmodule CustomAction do
    @behaviour Action
    import RasaSdk.Actions.Context

    def name(), do: "custom_action"

    def run(context) do
      context
      |> add_event(Events.slot_set("test", "foo"))
      |> add_event(Events.slot_set("test2", "boo"))
    end
  end

  defmodule CustomFormAction do
    use FormAction

    def name(), do: "some_form"

    def required_slots(_action), do: ["some_slot"]

    def slot_mappings() do
      %{
        "some_slot" => from_entity("some_entity")
      }
    end

    def submit(context), do: context
  end

  setup do
    RasaSdk.Actions.Registry.register_actions([
      CustomAction,
      CustomFormAction
    ])
  end

  describe "registration" do
    test "unknown action" do
      context =
        %Request{next_action: "bogus_action"}
        |> Context.new()
        |> RasaSdk.Actions.Registry.execute()

      assert context.error == %ResponseRejected{
               action_name: "bogus_action",
               error: "action not found"
             }
    end

    test "valid action registration" do
      context =
        %Request{next_action: "custom_action"}
        |> Context.new()
        |> RasaSdk.Actions.Registry.execute()

      assert context.response.events == [
               %{event: "slot", name: "test", timestamp: nil, value: "foo"},
               %{event: "slot", name: "test2", timestamp: nil, value: "boo"}
             ]
    end
  end

  describe "tracker" do
    test "tracker latest_input_channel" do
      context = %Context{
        request: %Request{
          tracker: %Tracker{
            events: [
              Events.action_executed("action_listen"),
              Events.user_uttered("my message text", %{}, "superchat")
            ],
            latest_input_channel: "superchat"
          }
        }
      }

      assert Context.latest_input_channel(context) == "superchat"
    end
  end
end
