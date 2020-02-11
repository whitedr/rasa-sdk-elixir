defmodule RasaSdk.Actions.Plug do
  import Plug.Conn
  alias RasaSdk.Actions.{Context, Registry}
  require Logger

  def init(options) do
    # initialize options
    options
  end

  def call(%Plug.Conn{body_params: body_params} = conn, _opts) do
    context =
      body_params
      |> Poison.Decode.decode(as: %RasaSdk.Model.Request{})
      |> Context.new()
      |> Registry.execute()

    conn |> send_response(context)
  end

  defp send_response(conn, %Context{response: response, error: nil}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(response))
  end

  defp send_response(conn, %Context{error: error}) do
    Logger.error("Action #{error.action_name} failed with reason: #{error.error}")

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Poison.encode!(error))
  end
end
