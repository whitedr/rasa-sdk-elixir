defmodule RasaSdk.Actions.FormAction do
  alias RasaSdk.Actions.Context
  alias RasaSdk.Model.Request
  alias RasaSdk.Model.ResponseOk
  alias RasaSdk.Model.{ParseResult, Tracker}

  require Logger

  @callback on_activate(Context.t()) :: Context.t()
  @callback required_slots(Context.t()) :: [String.t()]
  @callback slot_mappings() :: map()
  @callback validate_slot(Context.t(), String.t(), term()) :: Context.t()
  @callback submit(Context.t()) :: Context.t()

  defmacro __using__(_) do
    quote do
      @behaviour RasaSdk.Actions.Action
      import RasaSdk.Actions.Context
      import RasaSdk.Actions.Events

      require Logger

      # this slot is used to store information needed
      # to do the form handling
      @requested_slot "requested_slot"

      # default implementation, overridable
      def on_activate(context), do: context

      # default implementation, overridable
      def slot_mappings() do
        %{}
      end

      # default implementation, overridable
      def validate_slot(context, slot, value) do
        add_event(context, slot_set(slot, value))
      end

      def run(%Context{} = context) do
        context
        |> activate()
        |> validate()
        |> set_slots_from_events()
        |> request_slots()
      end

      def activate(%Context{request: %Request{tracker: tracker}} = context) do
        if not is_nil(Map.get(tracker.active_form, :name)) do
          Logger.debug("The form #{inspect(tracker.active_form)} is active")
        else
          Logger.debug("There is no active form")
        end

        if Map.get(tracker.active_form, :name) == name() do
          context
        else
          Logger.debug("Activated the form #{name()}")
          context = add_event(context, form(name()))

          prefilled_slots =
            required_slots(context)
            |> Enum.reject(fn slot_name -> should_request_slot(context, slot_name) end)
            |> Enum.map(fn slot_name -> {slot_name, get_slot(context, slot_name)} end)
            |> Enum.into(%{})

          if Enum.empty?(prefilled_slots) do
            Logger.debug("No pre-filled required slots to validate.")

            context
            |> set_active_form(name(), true)
            |> on_activate()
          else
            Logger.debug("Validating pre-filled required slots. #{inspect(prefilled_slots)}")

            Enum.reduce(prefilled_slots, context, fn {slot, value}, acc ->
              validate_slot(acc, slot, value)
            end)
            |> set_active_form(name(), true)
            |> on_activate()
          end
        end
      end

      def validate(
            %Context{
              request: %Request{
                tracker:
                  %Tracker{
                    latest_action_name: "action_listen",
                    active_form: %{validate: true}
                  } = tracker
              }
            } = context
          ) do
        Logger.debug("Validating user input #{inspect(tracker.latest_message)}")
        # extract other slots that were not requested
        # but set by corresponding entity or trigger intent mapping
        slot_values = extract_other_slots(context)

        # extract requested_slot
        slot_to_fill = get_slot(context, @requested_slot)

        if not is_nil(slot_to_fill) do
          slot_values =
            slot_values
            |> Map.merge(extract_requested_slot(context))

          if Enum.empty?(slot_values) do
            # TODO: raise exception instead?
            context
            |> set_error(name(), "Failed to extract slot #{slot_to_fill} with action #{name()}")
          else
            Logger.debug("Validating extracted slots: #{inspect(slot_values)}")

            Enum.reduce(slot_values, context, fn {slot, value}, acc ->
              validate_slot(acc, slot, value)
            end)
          end
        else
          Logger.debug("Validating extracted slots: #{inspect(slot_values)}")

          Enum.reduce(slot_values, context, fn {slot, value}, acc ->
            validate_slot(acc, slot, value)
          end)
        end
      end

      def validate(%Context{} = context) do
        Logger.debug("Skipping validation")
        context
      end

      defp set_slots_from_events(
             %Context{request: %Request{tracker: tracker}, response: %ResponseOk{events: events}} =
               context
           ) do
        Enum.reduce(events, context, fn event, acc ->
          if event.event == "slot" do
            set_slot(acc, event.name, event.value)
          else
            acc
          end
        end)
      end

      defp request_slots(
             %Context{request: %Request{tracker: tracker}, response: %ResponseOk{events: events}} =
               context
           ) do
        if not Enum.member?(events, form(nil)) do
          slot_name = request_next_slot(context)

          if is_nil(slot_name) do
            # there is nothing more to request, so we can submit
            Logger.debug("Submitting the form #{name()}")

            context
            |> submit()
            |> deactivate()
          else
            Logger.debug("Request next slot #{slot_name}")

            context
            |> utter_message([template: "utter_ask_#{slot_name}"], tracker.slots)
            |> add_event(slot_set(@requested_slot, slot_name))
          end
        else
          context
        end
      end

      defp request_next_slot(context) do
        slots_needed =
          required_slots(context)
          |> Enum.filter(fn slot_name -> should_request_slot(context, slot_name) end)

        if not Enum.empty?(slots_needed) do
          List.first(slots_needed)
        end
      end

      defp should_request_slot(context, slot_name) do
        value = get_slot(context, slot_name)
        is_nil(value)
      end

      # private functions every form can utilize
      defp from_entity(entity, opts \\ []) do
        %{
          type: "from_entity",
          entity: entity,
          intent: to_list(Keyword.get(opts, :intent, [])),
          not_intent: to_list(Keyword.get(opts, :not_intent, []))
        }
      end

      defp from_trigger_intent(value, opts \\ []) do
        %{
          type: "from_trigger_intent",
          value: value,
          intent: to_list(Keyword.get(opts, :intent, [])),
          not_intent: to_list(Keyword.get(opts, :not_intent, []))
        }
      end

      defp from_intent(value, opts \\ []) do
        %{
          type: "from_intent",
          value: value,
          intent: to_list(Keyword.get(opts, :intent, [])),
          not_intent: to_list(Keyword.get(opts, :not_intent, []))
        }
      end

      defp from_text(opts \\ []) do
        %{
          type: "from_text",
          intent: to_list(Keyword.get(opts, :intent, [])),
          not_intent: to_list(Keyword.get(opts, :not_intent, []))
        }
      end

      defp to_list(value) when is_list(value), do: value

      defp to_list(value), do: [value]

      defp get_mappings_for_slot(slot_to_fill) do
        slot_mapping = Map.get(slot_mappings(), slot_to_fill, [from_entity(slot_to_fill)])

        if is_list(slot_mapping) do
          slot_mapping
        else
          [slot_mapping]
        end
      end

      defp intent_is_desired(requested_slot_mapping, %Context{request: %Request{tracker: tracker}}) do
        intents = Map.get(requested_slot_mapping, :intent, [])
        not_intents = Map.get(requested_slot_mapping, :not_intent, [])

        intent = Map.get(tracker.latest_message, :intent, %{})

        intent =
          if is_nil(intent) do
            nil
          else
            intent.name
          end

        intent_not_blacklisted = Enum.empty?(intents) and not Enum.member?(not_intents, intent)
        intent_not_blacklisted or Enum.member?(intents, intent)
      end

      defp get_entity_value(entity_name, %Context{} = context) do
        values = get_latest_entity_values(context, entity_name)

        cond do
          Enum.empty?(values) -> nil
          Enum.count(values) == 1 -> List.first(values)
          true -> values
        end
      end

      def extract_other_slots(%Context{} = context) do
        slot_to_fill = get_slot(context, @requested_slot)

        required_slots(context)
        |> Enum.reject(fn slot -> slot == slot_to_fill end)
        |> Enum.flat_map(fn slot ->
          get_mappings_for_slot(slot)
          |> Enum.map(fn mapping -> Map.put(mapping, :slot, slot) end)
        end)
        |> Enum.reduce(%{}, fn mapping, acc ->
          value = get_other_slot_value(mapping, context)

          if is_nil(value) do
            acc
          else
            Map.put(acc, mapping.slot, value)
          end
        end)
      end

      defp get_other_slot_value(%{type: "from_entity"} = slot_mapping, context) do
        if slot_mapping.entity == slot_mapping.slot and intent_is_desired(slot_mapping, context) do
          get_entity_value(slot_mapping.slot, context)
        end
      end

      defp get_other_slot_value(
             %{type: "from_trigger_intent"} = slot_mapping,
             %Context{request: %Request{tracker: tracker}} = context
           ) do
        if Map.get(tracker.active_form, :name) != name() and
             intent_is_desired(slot_mapping, context) do
          Map.get(slot_mapping, :value)
        end
      end

      defp get_other_slot_value(_, _), do: nil

      def extract_requested_slot(%Context{request: %Request{tracker: tracker}} = context) do
        slot_to_fill = get_slot(context, @requested_slot)
        Logger.debug("Trying to extract requested slot #{slot_to_fill}")

        get_mappings_for_slot(slot_to_fill)
        |> Enum.reduce(%{}, fn slot_mapping, res ->
          Logger.debug("Got mapping #{inspect(slot_mapping)}")

          if is_nil(Map.get(res, slot_to_fill)) and intent_is_desired(slot_mapping, context) do
            case get_requested_slot_value(slot_mapping, context) do
              nil ->
                res

              value ->
                Logger.debug(
                  "Successfully extracted '#{inspect(value)}' for requested slot '#{slot_to_fill}'"
                )

                Map.put(res, slot_to_fill, value)
            end
          else
            res
          end
        end)
      end

      defp get_requested_slot_value(%{type: "from_entity", entity: entity}, context) do
        get_entity_value(entity, context)
      end

      defp get_requested_slot_value(%{type: "from_intent", value: value}, _), do: value

      defp get_requested_slot_value(%{type: "from_trigger_intent"}, _), do: nil

      defp get_requested_slot_value(%{type: "from_text"}, %Context{
             request: %Request{tracker: %Tracker{latest_message: %ParseResult{text: text}}}
           }) do
        text
      end

      defp get_requested_slot_value(_, _), do: nil

      defp deactivate(%Context{} = context) do
        Logger.debug("Deactivating the form #{name()}")

        context
        |> add_event(form(nil))
        |> add_event(slot_set(@requested_slot, nil))
      end

      defoverridable on_activate: 1, slot_mappings: 0, validate: 1, validate_slot: 3
    end
  end
end
