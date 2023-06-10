@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

@export var condition: QuestCondition: set = set_condition

@onready var required_checkbox := %RequiredCheckbox
@onready var active_checkbox := %ActiveCheckbox
@onready var always_checkbox := %AlwaysCheckbox

func _ready():
    set_condition(condition)

func _process(delta):
    if not condition:
        return
    required_checkbox.button_pressed = condition.required
    active_checkbox.button_pressed = condition.active
    always_checkbox.button_pressed = condition.always
    set_active_shade(condition.active or condition.always)

func set_condition(new_condition):
    condition = new_condition
    if not condition or not is_inside_tree():
        return
    title = condition.name

func _on_required_checkbox_toggled(button_pressed:bool):
    condition.always = button_pressed

func _on_active_checkbox_toggled(button_pressed:bool):
    condition.active = button_pressed

func _on_always_checkbox_toggled(button_pressed:bool):
    condition.always = button_pressed
