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

    try do
      send_response(conn, Registry.execute(context))
    rescue
      error ->
        error_msg = Exception.message(error)

        context =
          context
          |> Context.set_error(context.request.next_action, error_msg)

        send_response(conn, context)
    end
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
