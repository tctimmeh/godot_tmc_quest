@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

@export var quest: Quest: set = set_quest

@onready var required_checkbox := %RequiredCheckbox
@onready var active_checkbox := %ActiveCheckbox
@onready var hidden_checkbox := %HiddenCheckbox

func _ready():
    set_quest(quest)

func _process(delta):
    if not quest:
        return
    required_checkbox.button_pressed = quest.required
    active_checkbox.button_pressed = quest.active
    hidden_checkbox.button_pressed = quest.hidden
    set_active_shade(quest.active)

func set_quest(new_quest):
    quest = new_quest
    if not quest or not is_inside_tree():
        return

    theme_type_variation = "QuestGraphNode" if quest.parent else "RootQuestGraphNode"
    title = quest.name

func _on_required_checkbox_pressed():
    quest.required = required_checkbox.button_pressed

func _on_active_checkbox_pressed():
    quest.active = active_checkbox.button_pressed

func _on_hidden_checkbox_pressed():
    quest.hidden = hidden_checkbox.button_pressed
