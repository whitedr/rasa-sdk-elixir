# NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
# https://openapi-generator.tech
# Do not edit the class manually.

defmodule RasaSdk.Model.Tracker do
  @moduledoc """
  Conversation tracker which stores the conversation state.
  """
  alias RasaSdk.Model.ParseResult
  alias RasaSdk.Model.Event
  alias RasaSdk.Model.TrackerActiveForm

  @derive [Poison.Encoder]
  defstruct [
    :conversation_id,
    :slots,
    :latest_message,
    :latest_event_time,
    :followup_action,
    :paused,
    :events,
    :latest_input_channel,
    :latest_action_name,
    :active_form
  ]

  @type t :: %__MODULE__{
    conversation_id: String.t | nil,
    slots: [Map] | nil,
    latest_message: ParseResult | nil,
    latest_event_time: float() | nil,
    followup_action: String.t | nil,
    paused: boolean() | nil,
    events: [Event] | nil,
    latest_input_channel: String.t | nil,
    latest_action_name: String.t | nil,
    active_form: TrackerActiveForm | nil
  }
end

defimpl Poison.Decoder, for: RasaSdk.Model.Tracker do
  import RasaSdk.Deserializer
  def decode(value, options) do
    value
    |> deserialize(:latest_message, :struct, RasaSdk.Model.ParseResult, options)
    |> deserialize(:events, :list, RasaSdk.Model.Event, options)
    |> deserialize(:active_form, :struct, RasaSdk.Model.TrackerActiveForm, options)
  end
end

