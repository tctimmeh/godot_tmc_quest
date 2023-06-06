@tool
extends GraphNode

const input_port_color := Color("#dd2020")
const condition_port_color := Color("0099ff")
const child_port_color := Color("#22bb11")

@export var quest: Quest: set = set_quest

@onready var required_checkbox := $RequiredCheckbox
@onready var active_checkbox := $ActiveCheckbox
@onready var hidden_checkbox := $HiddenCheckbox

func _ready():
    set_quest(quest)

func set_quest(new_quest):
    quest = new_quest
    if not quest or not is_inside_tree():
        return

    title = quest.name
    required_checkbox.button_pressed = quest.required
    active_checkbox.button_pressed = quest.active
    hidden_checkbox.button_pressed = quest.hidden
