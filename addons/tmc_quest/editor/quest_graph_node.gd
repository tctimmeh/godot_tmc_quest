@tool
extends GraphNode

signal context_requested

# const action_port_color := Color("#dd2020")
# const condition_port_color := Color("0099ff")
# const quest_port_color := Color("#22bb11")

@export var quest: Quest: set = set_quest

@onready var required_checkbox := %RequiredCheckbox
@onready var active_checkbox := %ActiveCheckbox
@onready var hidden_checkbox := %HiddenCheckbox

func _ready():
    set_quest(quest)

func _process(delta):
    required_checkbox.button_pressed = quest.required
    active_checkbox.button_pressed = quest.active
    hidden_checkbox.button_pressed = quest.hidden
    set_active_shade()

func set_active_shade():
    if quest and quest.active:
        self_modulate = Color.WHITE
    else:
        self_modulate = Color.DARK_GRAY

func set_quest(new_quest):
    quest = new_quest
    if not quest or not is_inside_tree():
        return

    theme_type_variation = "QuestGraphNode" if quest.parent else "RootQuestGraphNode"

    title = quest.name
    required_checkbox.button_pressed = quest.required
    active_checkbox.button_pressed = quest.active
    hidden_checkbox.button_pressed = quest.hidden


func _on_required_checkbox_pressed():
    quest.required = required_checkbox.button_pressed


func _on_active_checkbox_pressed():
    quest.active = active_checkbox.button_pressed


func _on_hidden_checkbox_pressed():
    quest.hidden = hidden_checkbox.button_pressed


func _on_gui_input(event:InputEvent):
    if event is InputEventMouseButton \
            and event.pressed \
            and event.button_index == MOUSE_BUTTON_RIGHT \
            :
        context_requested.emit()
