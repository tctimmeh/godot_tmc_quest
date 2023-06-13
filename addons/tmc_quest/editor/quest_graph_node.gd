@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

var quest: Quest: set = set_quest

@onready var required_checkbox := %RequiredCheckbox
@onready var active_checkbox := %ActiveCheckbox
@onready var hidden_checkbox := %HiddenCheckbox
@onready var outcome_label := %OutcomeLabel

var active_before_simulation: bool

func _process(delta):
    if not quest:
        return
    title = quest.name
    required_checkbox.button_pressed = quest.required
    active_checkbox.button_pressed = quest.active
    hidden_checkbox.button_pressed = quest.hidden
    outcome_label.text = Quest.QuestOutcome.keys()[quest.outcome]
    set_node_active(quest.active)

func set_quest(new_quest: Quest):
    quest = new_quest
    if not quest:
        return
    title = quest.name

func start_simulation():
    super()
    quest.outcome = Quest.QuestOutcome.Incomplete
    active_before_simulation = quest.active

func end_simulation():
    super()
    quest.outcome = Quest.QuestOutcome.Incomplete
    quest.active = active_before_simulation

func _on_required_checkbox_toggled(button_pressed:bool):
    quest.required = button_pressed

func _on_active_checkbox_toggled(button_pressed:bool):
    quest.active = button_pressed

func _on_hidden_checkbox_toggled(button_pressed:bool):
    quest.hidden = button_pressed
