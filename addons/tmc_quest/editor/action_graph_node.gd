@tool
extends GraphNode

signal context_requested

@export var action: QuestAction: set = set_action

func _ready():
    set_action(action)

func set_action(new_action):
    action = new_action
    if not action or not is_inside_tree():
        return
    title = action.name

func _on_gui_input(event:InputEvent):
    if event is InputEventMouseButton \
            and event.pressed \
            and event.button_index == MOUSE_BUTTON_RIGHT \
            :
        context_requested.emit()
