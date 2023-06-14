@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

var condition: QuestCondition: set = set_condition

@onready var required_checkbox := %RequiredCheckbox
@onready var always_checkbox := %AlwaysCheckbox
@onready var passed_checkbox := %PassedCheckbox

func _process(delta):
    if not condition:
        return
    required_checkbox.button_pressed = condition.required
    always_checkbox.button_pressed = condition.always
    passed_checkbox.button_pressed = condition.passed
    set_node_active(condition.active)

func set_condition(new_condition: QuestCondition):
    condition = new_condition
    if not condition:
        return
    title = condition.name

func start_simulation():
    super()
    condition.passed = false

func end_simulation():
    super()
    condition.passed = false

func _on_passed_check_pressed():
    var passed = passed_checkbox.button_pressed
    if passed:
        condition.succeed()
    else:
        condition.fail()

func _on_required_checkbox_toggled(button_pressed:bool):
    condition.required = button_pressed

func _on_always_checkbox_toggled(button_pressed:bool):
    condition.always = button_pressed

func _on_passed_checkbox_toggled(button_pressed:bool):
    var passed = button_pressed
    if passed:
        condition.succeed()
    else:
        condition.fail()
