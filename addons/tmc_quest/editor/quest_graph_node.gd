@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

var quest: Quest: set = set_quest

@onready var required_checkbox := %RequiredCheckbox
@onready var active_checkbox := %ActiveCheckbox
@onready var hidden_checkbox := %HiddenCheckbox

func _process(delta):
    title = quest.name
    required_checkbox.button_pressed = quest.required
    active_checkbox.button_pressed = quest.active
    hidden_checkbox.button_pressed = quest.hidden

func set_quest(new_quest: Quest):
    quest = new_quest
    if not quest:
        return
    title = quest.name

func _on_required_checkbox_toggled(button_pressed:bool):
    quest.required = button_pressed

func _on_active_checkbox_toggled(button_pressed:bool):
    quest.active = button_pressed

func _on_hidden_checkbox_toggled(button_pressed:bool):
    quest.hidden = button_pressed
