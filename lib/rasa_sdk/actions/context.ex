defmodule RasaSdk.Actions.Context do
  alias RasaSdk.Model.{ParseResult, Tracker}
  alias RasaSdk.Model.InlineObject, as: Request
  alias RasaSdk.Model.InlineResponse200, as: Response
  alias RasaSdk.Model.InlineResponse400, as: Error

  require Logger

  defstruct [
    :conversation_id,
    :request,
    :response,
    :error
  ]

  @type t :: %__MODULE__{
          :conversation_id => String.t() | nil,
          :request => Request.t() | nil,
          :response => Response.t() | nil,
          :error => Error.t() | nil
        }

  def new(request) do
    %__MODULE__{
      request: request,
      response: %Response{
        events: [],
        responses: []
      }
    }
  end

  @doc """
  Return the currently set values of the slots
  """
  def current_slot_values(%__MODULE__{request: %Request{tracker: %Tracker{slots: slots}}}),
    do: slots

  @doc """
  Retrieves the value of a slot.
  """
  def get_slot(%__MODULE__{request: %Request{tracker: %Tracker{slots: slots}}}, key) do
    if Map.has_key?(slots, key) do
      Map.get(slots, key)
    else
      Logger.info("Tried to access non existent slot #{key}")
      nil
    end
  end

  def set_slot(%__MODULE__{} = context, key, value) do
    update_in(
      context,
      [Access.key(:request), Access.key(:tracker), Access.key(:slots)],
      fn slots ->
        Map.put(slots, key, value)
      end
    )
  end

  def set_active_form(%__MODULE__{} = context, name, validate) do
    update_in(context, [Access.key(:request), Access.key(:tracker)], fn tracker ->
      Map.put(tracker, :active_form, %{name: name, validate: validate})
    end)
  end

  @doc """
  Get entity values found for the passed entity name in latest msg.

  If you are only interested in the first entity of a given type use
  `get_latest_entity_values(tracker, "my_entity_name") |> List.first()`.
  If no entity is found `nil` is the default result.
  """
  def get_latest_entity_values(
        %__MODULE__{
          request: %Request{tracker: %Tracker{latest_message: nil}}
        },
        _
      ) do
    []
  end

  def get_latest_entity_values(
        %__MODULE__{
          request: %Request{tracker: %Tracker{latest_message: %ParseResult{entities: nil}}}
        },
        _
      ) do
    []
  end

  def get_latest_entity_values(
        %__MODULE__{
          request: %Request{tracker: %Tracker{latest_message: %ParseResult{entities: entities}}}
        },
        entity_type
      ) do
    entities
    |> Enum.filter(fn e -> e.entity == entity_type end)
    |> Enum.map(fn e -> e.value end)
  end

  @doc """
  Get the name of the input_channel of the latest UserUttered event
  """
  def latest_input_channel(%__MODULE__{
        request: %Request{tracker: %Tracker{latest_input_channel: latest_input_channel}}
      }) do
    latest_input_channel
    # latest_user_event =
    #   events
    #   |> Enum.reverse()
    #   |> Enum.find(fn event -> event.event == "user" end)

    # if not is_nil(latest_user_event) do
    #   latest_user_event.input_channel
    # end
  end

  def latest_event_time(%__MODULE__{
        request: %Request{tracker: %Tracker{latest_event_time: latest_event_time}}
      }) do
    latest_event_time
  end

  # def latest_event_time(%__MODULE__{tracker: %Tracker{events: nil}}), do: nil

  # def latest_event_time(%__MODULE__{tracker: %Tracker{events: events}}) do
  #   case List.last(events) do
  #     nil -> nil
  #     event -> Map.get(event, "timestamp")
  #   end
  # end

  @default_message %{
    image: nil,
    json_message: nil,
    template: nil,
    attachment: nil,
    text: nil,
    buttons: nil
  }
  @spec utter_message(__MODULE__.t(), keyword(), map()) :: __MODULE__.t()
  def utter_message(
        %__MODULE__{} = context,
        options \\ [],
        data \\ %{}
      ) do
    message =
      options
      |> Enum.into(@default_message)
      |> Map.merge(data)

    update_in(context, [Access.key(:response), Access.key(:responses)], fn responses ->
      responses ++ [message]
    end)
  end

  @spec add_event(__MODULE__.t(), map()) :: __MODULE__.t()
  def add_event(%__MODULE__{} = context, event) do
    update_in(context, [Access.key(:response), Access.key(:events)], fn events ->
      events ++ [event]
    end)
  end

  def set_error(%__MODULE__{} = context, action_name, error) do
    Map.replace!(context, :error, %Error{action_name: action_name, error: error})
  end
end
