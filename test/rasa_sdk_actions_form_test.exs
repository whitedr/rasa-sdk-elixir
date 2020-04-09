defmodule RasaSdkActionsFormTest do
  use ExUnit.Case

  alias RasaSdk.Actions.{Context, Events, FormAction}
  alias RasaSdk.Model.{Entity, Intent, ParseResult, Tracker}
  alias RasaSdk.Model.Request

  defmodule SlotFromEntityNoIntent do
    use FormAction

    def name(), do: "slot_from_entity_no_intent"
    def required_slots(_), do: ["some_slot"]
    def slot_mappings(), do: %{"some_slot" => from_entity("some_entity")}
    def submit(context), do: context
  end

  defmodule SlotFromEntityWithIntent do
    use FormAction

    def name(), do: "slot_from_entity_with_intent"
    def required_slots(_), do: ["some_slot"]
    def slot_mappings(), do: %{"some_slot" => from_entity("some_entity", intent: "some_intent")}
    def submit(context), do: context
  end

  defmodule SlotFromEntityWithNotIntent do
    use FormAction

    def name(), do: "slot_from_entity_with_not_intent"
    def required_slots(_), do: ["some_slot"]

    def slot_mappings(),
      do: %{"some_slot" => from_entity("some_entity", not_intent: "some_intent")}

    def submit(context), do: context
  end

  defmodule SlotFromIntent do
    use FormAction

    def name(), do: "slot_from_intent"
    def required_slots(_), do: ["some_slot"]
    def slot_mappings(), do: %{"some_slot" => from_intent("some_value", intent: "some_intent")}
    def submit(context), do: context
  end

  defmodule SlotFromNotIntent do
    use FormAction

    def name(), do: "slot_from_not_intent"
    def required_slots(_), do: ["some_slot"]

    def slot_mappings(),
      do: %{"some_slot" => from_intent("some_value", not_intent: "some_intent")}

    def submit(context), do: context
  end

  defmodule SlotFromTextNoIntent do
    use FormAction

    def name(), do: "slot_from_text_no_intent"
    def required_slots(_), do: ["some_slot"]
    def slot_mappings(), do: %{"some_slot" => from_text()}
    def submit(context), do: context
  end

  defmodule SlotFromTextWithIntent do
    use FormAction

    def name(), do: "slot_from_text_with_intent"
    def required_slots(_), do: ["some_slot"]
    def slot_mappings(), do: %{"some_slot" => from_text(intent: "some_intent")}
    def submit(context), do: context
  end

  defmodule SlotFromTextWithNotIntent do
    use FormAction

    def name(), do: "slot_from_text_with_not_intent"
    def required_slots(_), do: ["some_slot"]
    def slot_mappings(), do: %{"some_slot" => from_text(not_intent: "some_intent")}
    def submit(context), do: context
  end

  defmodule SlotFromTriggerIntent do
    use FormAction

    def name(), do: "slot_from_tigger_intent"
    def required_slots(_), do: ["some_slot"]

    def slot_mappings(),
      do: %{"some_slot" => from_trigger_intent("some_value", intent: "trigger_intent")}

    def submit(context), do: context
  end

  defmodule OtherSlotsNoIntent do
    use FormAction

    def name(), do: "other_slots_no_intent"
    def required_slots(_), do: ["some_slot", "some_other_slot"]
    def submit(context), do: context
  end

  defmodule OtherSlotsWithIntent do
    use FormAction

    def name(), do: "other_slots_with_intent"
    def required_slots(_), do: ["some_slot", "some_other_slot"]

    def slot_mappings() do
      %{
        "some_other_slot" => from_entity("some_other_slot", intent: "some_intent")
      }
    end

    def submit(context), do: context
  end

  defmodule ValidateForm do
    use FormAction

    def name(), do: "validate_form"
    def required_slots(_), do: ["some_slot", "some_other_slot"]
    def submit(context), do: context
  end

  defmodule ValidateSlotForm do
    use FormAction

    def name(), do: "validate_slot_form"
    def required_slots(_), do: ["some_slot", "some_other_slot"]

    def validate_slot(context, "some_slot", "some_value") do
      context
      |> add_event(slot_set("some_slot", "validated_value"))
      |> add_event(slot_set("some_other_slot", "other_value"))
    end

    def submit(context), do: context
  end

  defmodule ValidateExtractedNoRequested do
    use FormAction

    def name(), do: "validate_extracted_no_requested"
    def required_slots(_), do: ["some_slot", "some_other_slot"]

    def validate_slot(context, "some_slot", "some_value") do
      context
      |> add_event(slot_set("some_slot", "validated_value"))
    end

    def submit(context), do: context
  end

  defmodule ValidatePrefilledSlots do
    use FormAction

    def name(), do: "validate_prefilled_slots"
    def required_slots(_), do: ["some_slot", "some_other_slot"]

    def validate_slot(context, "some_slot", "some_value") do
      context
      |> add_event(slot_set("some_slot", "validated_value"))
    end

    def validate_slot(context, "some_slot", _) do
      context
      |> add_event(slot_set("some_slot", nil))
    end

    def validate_slot(context, slot, value) do
      context
      |> add_event(slot_set(slot, value))
    end

    def submit(context), do: context
  end

  defmodule ValidateTriggerSlots do
    use FormAction

    def name(), do: "validate_trigger_slots"
    def required_slots(_), do: ["some_slot"]

    def slot_mappings() do
      %{
        "some_slot" => from_trigger_intent("some_value", intent: "trigger_intent")
      }
    end

    def submit(context), do: context
  end

  defmodule ActivateIfRequired do
    use FormAction

    def name(), do: "activate_if_required"
    def required_slots(_), do: ["some_slot", "some_other_slot"]
    def submit(context), do: context
  end

  defmodule ValidateIfRequired do
    use FormAction

    def name(), do: "validate_if_required"
    def required_slots(_), do: ["some_slot", "some_other_slot"]
    def submit(context), do: context
  end

  defmodule EarlyDeactivation do
    use FormAction

    def name(), do: "early_deactivation"
    def required_slots(_), do: ["some_slot", "some_other_slot"]
    def validate(context), do: deactivate(context)
    def submit(context), do: context
  end

  setup do
    RasaSdk.Actions.Registry.register_actions([
      SlotFromEntityNoIntent,
      SlotFromEntityWithIntent,
      SlotFromEntityWithNotIntent,
      SlotFromIntent,
      SlotFromNotIntent,
      SlotFromTextNoIntent,
      SlotFromTextWithIntent,
      SlotFromTextWithNotIntent,
      SlotFromTriggerIntent
    ])
  end

  describe "forms - extract" do
    test "requested slot from entity no intent" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_entity", value: "some_value"}]
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromEntityNoIntent.extract_requested_slot(context)
      assert slot_values == %{"some_slot" => "some_value"}
    end

    test "requested slot from entity with intent" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_entity", value: "some_value"}],
              intent: %Intent{name: "some_intent", confidence: 1.0}
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromEntityWithIntent.extract_requested_slot(context)
      assert slot_values == %{"some_slot" => "some_value"}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_entity", value: "some_value"}],
              intent: %Intent{name: "some_other_intent", confidence: 1.0}
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromEntityWithIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{}
    end

    test "requested slot from entity with not intent" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_entity", value: "some_value"}],
              intent: %Intent{name: "some_intent", confidence: 1.0}
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromEntityWithNotIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_entity", value: "some_value"}],
              intent: %Intent{name: "some_other_intent", confidence: 1.0}
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromEntityWithNotIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{"some_slot" => "some_value"}
    end

    test "requested slot from intent" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              intent: %Intent{name: "some_intent", confidence: 1.0}
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{"some_slot" => "some_value"}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              intent: %Intent{name: "some_other_intent", confidence: 1.0}
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{}
    end

    test "requested slot from not intent" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              intent: %Intent{name: "some_intent", confidence: 1.0}
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromNotIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              intent: %Intent{name: "some_other_intent", confidence: 1.0}
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromNotIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{"some_slot" => "some_value"}
    end

    test "requested slot from text no intent" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              text: "some_text"
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromTextNoIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{"some_slot" => "some_text"}
    end

    test "requested slot from text with intent" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              intent: %Intent{name: "some_intent", confidence: 1.0},
              text: "some_text"
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromTextWithIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{"some_slot" => "some_text"}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              intent: %Intent{name: "some_other_intent", confidence: 1.0},
              text: "some_text"
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromTextWithIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{}
    end

    test "requested slot from text with not intent" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              intent: %Intent{name: "some_intent", confidence: 1.0},
              text: "some_text"
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromTextWithNotIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              intent: %Intent{name: "some_other_intent", confidence: 1.0},
              text: "some_text"
            }
          }
        }
        |> Context.new()

      slot_values = SlotFromTextWithNotIntent.extract_requested_slot(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{"some_slot" => "some_text"}
    end

    test "trigger slots" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{},
            latest_message: %ParseResult{
              intent: %Intent{name: "trigger_intent", confidence: 1.0}
            },
            active_form: %{}
          }
        }
        |> Context.new()

      slot_values = SlotFromTriggerIntent.extract_other_slots(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{"some_slot" => "some_value"}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{},
            latest_message: %ParseResult{
              intent: %Intent{name: "other_intent", confidence: 1.0}
            },
            active_form: %{}
          }
        }
        |> Context.new()

      slot_values = SlotFromTriggerIntent.extract_other_slots(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{},
            latest_message: %ParseResult{
              intent: %Intent{name: "trigger_intent", confidence: 1.0}
            },
            active_form: %{name: "slot_from_tigger_intent", validate: true, rejected: false}
          }
        }
        |> Context.new()

      slot_values = SlotFromTriggerIntent.extract_other_slots(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{}
    end

    test "other slots no intent" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_slot", value: "some_value"}]
            },
            active_form: %{}
          }
        }
        |> Context.new()

      slot_values = OtherSlotsNoIntent.extract_other_slots(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_other_slot", value: "some_other_value"}]
            },
            active_form: %{}
          }
        }
        |> Context.new()

      slot_values = OtherSlotsNoIntent.extract_other_slots(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{"some_other_slot" => "some_other_value"}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              entities: [
                %Entity{entity: "some_slot", value: "some_value"},
                %Entity{entity: "some_other_slot", value: "some_other_value"}
              ]
            },
            active_form: %{}
          }
        }
        |> Context.new()

      slot_values = OtherSlotsNoIntent.extract_other_slots(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{"some_other_slot" => "some_other_value"}
    end

    test "other slots with intent" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              entities: [
                %Entity{entity: "some_other_slot", value: "some_other_value"}
              ],
              intent: %Intent{name: "some_other_intent", confidence: 1.0}
            },
            active_form: %{}
          }
        }
        |> Context.new()

      slot_values = OtherSlotsWithIntent.extract_other_slots(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{}

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_message: %ParseResult{
              entities: [
                %Entity{entity: "some_other_slot", value: "some_other_value"}
              ],
              intent: %Intent{name: "some_intent", confidence: 1.0}
            },
            active_form: %{}
          }
        }
        |> Context.new()

      slot_values = OtherSlotsWithIntent.extract_other_slots(context)
      # check that the value was not extracted for incorrect intent
      assert slot_values == %{"some_other_slot" => "some_other_value"}
    end
  end

  describe "forms - validate" do
    test "validate" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              entities: [
                %Entity{entity: "some_slot", value: "some_value"},
                %Entity{entity: "some_other_slot", value: "some_other_value"}
              ]
            },
            active_form: %{validate: true}
          }
        }
        |> Context.new()

      context = ValidateForm.validate(context)

      assert context.response.events == [
               Events.slot_set("some_other_slot", "some_other_value"),
               Events.slot_set("some_slot", "some_value")
             ]

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              entities: [
                %Entity{entity: "some_other_slot", value: "some_other_value"}
              ]
            },
            active_form: %{validate: true}
          }
        }
        |> Context.new()

      context = ValidateForm.validate(context)

      assert context.response.events == [
               Events.slot_set("some_other_slot", "some_other_value")
             ]

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              entities: []
            },
            active_form: %{validate: true}
          }
        }
        |> Context.new()

      context = ValidateForm.validate(context)

      assert context.error.error == "Failed to extract slot some_slot with action validate_form"
    end

    test "set slot within" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_slot", value: "some_value"}]
            },
            active_form: %{validate: true}
          }
        }
        |> Context.new()

      context = ValidateSlotForm.validate(context)

      assert context.response.events == [
               Events.slot_set("some_slot", "validated_value"),
               Events.slot_set("some_other_slot", "other_value")
             ]
    end

    test "extracted no requested" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_slot", value: "some_value"}]
            },
            active_form: %{validate: true}
          }
        }
        |> Context.new()

      context = ValidateExtractedNoRequested.validate(context)

      assert context.response.events == [
               Events.slot_set("some_slot", "validated_value")
             ]
    end

    test "prefilled slots" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"some_slot" => "some_value", "some_other_slot" => "some_other_value"},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_slot", value: "some_bad_value"}],
              text: "some_text"
            },
            active_form: %{validate: true}
          }
        }
        |> Context.new()

      context = ValidatePrefilledSlots.activate(context)

      assert context.response.events == [
               Events.form("validate_prefilled_slots"),
               Events.slot_set("some_other_slot", "some_other_value"),
               Events.slot_set("some_slot", "validated_value")
             ]

      context = ValidatePrefilledSlots.validate(context)

      assert context.response.events == [
               Events.form("validate_prefilled_slots"),
               Events.slot_set("some_other_slot", "some_other_value"),
               Events.slot_set("some_slot", nil)
             ]
    end

    test "trigger slots" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              intent: %Intent{name: "trigger_intent", confidence: 1.0}
            },
            active_form: %{validate: true}
          }
        }
        |> Context.new()

      context = ValidateTriggerSlots.validate(context)

      assert context.response.events == [
               Events.slot_set("some_slot", "some_value")
             ]

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"intent" => %{"name" => "trigger_intent", "confidence" => 1.0}},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              intent: %Intent{name: "trigger_intent", confidence: 1.0}
            },
            active_form: %{
              name: "validate_trigger_slots",
              validate: true,
              rejected: false,
              trigger_message: %{
                "intent" => %{"name" => "trigger_intent", "confidence" => 1.0}
              }
            }
          }
        }
        |> Context.new()

      context = ValidateTriggerSlots.validate(context)
      assert context.response.events == []

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_other_slot"},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              entities: [%Entity{entity: "some_other_slot", value: "some_other_value"}],
              intent: %Intent{name: "trigger_intent", confidence: 1.0}
            },
            active_form: %{
              name: "validate_trigger_slots",
              validate: true,
              rejected: false,
              trigger_message: %{
                "intent" => %{"name" => "trigger_intent", "confidence" => 1.0}
              }
            }
          }
        }
        |> Context.new()

      context = ValidateTriggerSlots.validate(context)

      assert context.response.events == [
               Events.slot_set("some_other_slot", "some_other_value")
             ]
    end

    test "activate if required" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              intent: %Intent{name: "some_intent", confidence: 1.0},
              text: "some text"
            },
            active_form: %{}
          }
        }
        |> Context.new()

      context = ActivateIfRequired.activate(context)

      assert context.response.events == [
               Events.form("activate_if_required")
             ]

      context =
        %Request{
          tracker: %Tracker{
            slots: %{},
            latest_action_name: "action_listen",
            latest_message: %{},
            active_form: %{
              name: "activate_if_required",
              validate: true,
              rejected: false
            }
          }
        }
        |> Context.new()

      context = ActivateIfRequired.activate(context)

      assert context.response.events == []
    end

    test "validate if required" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              entities: [
                %Entity{entity: "some_slot", value: "some_value"},
                %Entity{entity: "some_other_slot", value: "some_other_value"}
              ]
            },
            active_form: %{
              name: "validate_if_required",
              validate: true,
              rejected: false
            }
          }
        }
        |> Context.new()

      context = ValidateIfRequired.validate(context)

      assert context.response.events == [
               Events.slot_set("some_other_slot", "some_other_value"),
               Events.slot_set("some_slot", "some_value")
             ]

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              entities: [
                %Entity{entity: "some_slot", value: "some_value"},
                %Entity{entity: "some_other_slot", value: "some_other_value"}
              ]
            },
            active_form: %{
              name: "validate_if_required",
              validate: false,
              rejected: true
            }
          }
        }
        |> Context.new()

      context = ValidateIfRequired.validate(context)

      assert context.response.events == []

      context =
        %Request{
          tracker: %Tracker{
            slots: %{"requested_slot" => "some_slot"},
            latest_action_name: "validate_if_required",
            latest_message: %ParseResult{
              entities: [
                %Entity{entity: "some_slot", value: "some_value"},
                %Entity{entity: "some_other_slot", value: "some_other_value"}
              ]
            },
            active_form: %{
              name: "validate_if_required",
              validate: true,
              rejected: false
            }
          }
        }
        |> Context.new()

      context = ValidateIfRequired.validate(context)

      assert context.response.events == []
    end

    test "early deactivation" do
      context =
        %Request{
          tracker: %Tracker{
            slots: %{"some_slot" => "some_value"},
            latest_action_name: "action_listen",
            latest_message: %ParseResult{
              entities: [
                %Entity{entity: "some_slot", value: "some_value"},
                %Entity{entity: "some_other_slot", value: "some_other_value"}
              ]
            },
            active_form: %{
              name: "early_deactivation",
              validate: true,
              rejected: false
            }
          }
        }
        |> Context.new()

      context = EarlyDeactivation.run(context)

      assert context.response.events == [
               Events.form(nil),
               Events.slot_set("requested_slot", nil)
             ]
    end
  end
end
