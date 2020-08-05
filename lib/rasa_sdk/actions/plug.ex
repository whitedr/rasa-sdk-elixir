defmodule RasaSdk.Actions.Plug do
  import Plug.Conn
  alias RasaSdk.Actions.{Context, Registry}
  require Logger

  def init(opts) do
    # initialize options
    opts
  end

  def call(%Plug.Conn{body_params: body_params} = conn, opts) do
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

        if Keyword.has_key?(opts, :default_error_handler) do
          default_error_handler = Keyword.get(opts, :default_error_handler)
          context = apply(default_error_handler, :run, [context])
          send_response(conn, context)
        else
          context =
            context
            |> Context.set_error(context.request.next_action, Exception.message(error))

          send_response(conn, context)
        end
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
