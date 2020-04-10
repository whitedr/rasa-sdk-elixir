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
        formatted_error = Exception.format(:error, error, __STACKTRACE__)

        Logger.error(
          "Action #{context.request.next_action} failed with reason: #{formatted_error}"
        )

        context =
          context
          |> Context.set_error(context.request.next_action, Exception.message(error))

        send_response(conn, context)
    end
  end

  defp send_response(conn, %Context{response: response, error: nil}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(response))
  end

  defp send_response(conn, %Context{error: error}) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Poison.encode!(error))
  end
end
