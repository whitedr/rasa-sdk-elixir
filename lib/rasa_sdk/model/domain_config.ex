# NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech).
# https://openapi-generator.tech
# Do not edit the class manually.

defmodule RasaSdk.Model.DomainConfig do
  @moduledoc """
  Addional option
  """

  @derive [Poison.Encoder]
  defstruct [
    :store_entities_as_slots
  ]

  @type t :: %__MODULE__{
    store_entities_as_slots: boolean() | nil
  }
end

defimpl Poison.Decoder, for: RasaSdk.Model.DomainConfig do
  def decode(value, _options) do
    value
  end
end

