@tool
class_name QuestBaseGraphNode
extends GraphNode

signal context_requested

func _on_gui_input(event:InputEvent):
    if event is InputEventMouseButton \
            and event.pressed \
            and event.button_index == MOUSE_BUTTON_RIGHT \
            :
        context_requested.emit()
