@tool
extends GraphNode

# const action_port_color := Color("#dd2020")
# const condition_port_color := Color("0099ff")
# const quest_port_color := Color("#22bb11")
# enum SlotType {
#     ParentChild = 1,
#     QuestCondition = 2,
#     Action = 3,
# }

signal context_requested

func _on_gui_input(event:InputEvent):
    if event is InputEventMouseButton \
            and event.pressed \
            and event.button_index == MOUSE_BUTTON_RIGHT \
            :
        context_requested.emit()

func set_active_shade(active):
    self_modulate = Color.WHITE if active else Color.DARK_GRAY
