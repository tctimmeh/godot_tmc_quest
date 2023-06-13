@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

var condition: QuestCondition: set = set_condition

@onready var required_checkbox := %RequiredCheckbox
@onready var always_checkbox := %AlwaysCheckbox

func _process(delta):
    if not condition:
        return
    required_checkbox.button_pressed = condition.required
    always_checkbox.button_pressed = condition.always

func set_condition(new_condition: QuestCondition):
    condition = new_condition
    if not condition:
        return
    title = condition.name

func _on_required_checkbox_toggled(button_pressed:bool):
    condition.required = button_pressed

func _on_always_checkbox_toggled(button_pressed:bool):
    condition.always = button_pressed
