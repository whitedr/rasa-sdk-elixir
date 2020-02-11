defmodule RasaSdk.Actions.Events do
  @type event :: %{atom() => any()}

  @spec user_uttered(String.t(), map(), String.t(), float() | nil) :: event
  def user_uttered(text, parse_data, input_channel, timestamp \\ nil) do
    %{
      event: "user",
      timestamp: timestamp,
      text: text,
      parse_data: parse_data,
      input_channel: input_channel
    }
  end

  @spec bot_uttered(String.t(), map(), map(), float() | nil) :: event
  def bot_uttered(text, data, metadata, timestamp \\ nil) do
    %{
      event: "bot",
      timestamp: timestamp,
      text: text,
      data: data,
      metadata: metadata
    }
  end

  @spec slot_set(String.t(), any(), float() | nil) :: event
  def slot_set(key, value, timestamp \\ nil) do
    %{
      event: "slot",
      timestamp: timestamp,
      name: key,
      value: value
    }
  end

  @spec restarted(float() | nil) :: event
  def restarted(timestamp \\ nil), do: %{event: "restart", timestamp: timestamp}

  @spec user_utterance_reverted(float() | nil) :: event
  def user_utterance_reverted(timestamp \\ nil), do: %{event: "rewind", timestamp: timestamp}

  @spec all_slots_reset(float() | nil) :: event
  def all_slots_reset(timestamp \\ nil), do: %{event: "reset_slots", timestamp: timestamp}

  @spec reminder_scheduled(String.t(), DateTime.t(), String.t(), boolean(), float() | nil) ::
          event
  def reminder_scheduled(
        action_name,
        trigger_date_time,
        name,
        kill_on_user_message,
        timestamp \\ nil
      ) do
    %{
      event: "reminder",
      timestamp: timestamp,
      action: action_name,
      date_time: DateTime.to_iso8601(trigger_date_time),
      name: name,
      kill_on_user_message: kill_on_user_message
    }
  end

  @spec reminder_cancelled(String.t(), String.t(), float() | nil) :: event
  def reminder_cancelled(action_name, name, timestamp \\ nil) do
    %{
      event: "cancel_reminder",
      timestamp: timestamp,
      action: action_name,
      name: name
    }
  end

  def action_reverted(timestamp \\ nil), do: %{event: "undo", timestamp: timestamp}

  def story_exported(timestamp \\ nil), do: %{event: "export", timestamp: timestamp}

  def followup_action(name, timestamp \\ nil) do
    %{event: "followup", name: name, timestamp: timestamp}
  end

  def conversation_paused(timestamp \\ nil), do: %{event: "pause", timestamp: timestamp}

  def conversation_resumed(timestamp \\ nil), do: %{event: "resume", timestamp: timestamp}

  def action_executed(action_name, policy \\ nil, confidence \\ nil, timestamp \\ nil) do
    %{
      event: "action",
      name: action_name,
      policy: policy,
      confidence: confidence,
      timestamp: timestamp
    }
  end

  def agent_uttered(text, data, timestamp \\ nil) do
    %{
      event: "agent",
      text: text,
      data: data,
      timestamp: timestamp
    }
  end

  def form(name, timestamp \\ nil) do
    %{event: "form", name: name, timestamp: timestamp}
  end

  def form_validation(validate, timestamp \\ nil) do
    %{event: "form_validation", validate: validate, timestamp: timestamp}
  end

  def action_execution_rejected(action_name, policy, confidence, timestamp \\ nil) do
    %{
      event: "action_execution_rejected",
      name: action_name,
      policy: policy,
      confidence: confidence,
      timestamp: timestamp
    }
  end
end
