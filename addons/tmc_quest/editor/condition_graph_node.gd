@tool
extends GraphNode

signal context_requested

const input_port_color := Color("#dd2020")
const condition_port_color := Color("0099ff")
const child_port_color := Color("#22bb11")

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

func set_condition(new_condition):
    condition = new_condition
    if not condition or not is_inside_tree():
        return

    title = condition.name
    required_checkbox.button_pressed = condition.required
    active_checkbox.button_pressed = condition.active
    always_checkbox.button_pressed = condition.always


func _on_required_checkbox_pressed():
    condition.required = required_checkbox.button_pressed


func _on_active_checkbox_pressed():
    condition.active = active_checkbox.button_pressed


func _on_gui_input(event:InputEvent):
    if event is InputEventMouseButton \
            and event.pressed \
            and event.button_index == MOUSE_BUTTON_RIGHT \
            :
        context_requested.emit()


func _on_always_checkbox_pressed():
    condition.always = always_checkbox.button_pressed
