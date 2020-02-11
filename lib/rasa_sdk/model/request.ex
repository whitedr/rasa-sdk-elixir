# NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
# https://openapi-generator.tech
# Do not edit the class manually.

defmodule RasaSdk.Model.Request do
  @moduledoc """
  Describes the action to be called and provides information on the current state of the conversation.
  """

  @derive [Poison.Encoder]
  defstruct [
    :next_action,
    :sender_id,
    :tracker,
    :domain
  ]

  @type t :: %__MODULE__{
    next_action: String.t | nil,
    sender_id: String.t | nil,
    tracker: Tracker | nil,
    domain: Domain | nil
  }
end

defimpl Poison.Decoder, for: RasaSdk.Model.Request do
  import RasaSdk.Deserializer
  def decode(value, options) do
    value
    |> deserialize(:tracker, :struct, RasaSdk.Model.Tracker, options)
    |> deserialize(:domain, :struct, RasaSdk.Model.Domain, options)
  end
end
