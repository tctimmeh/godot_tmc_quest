@tool
extends Control

signal inspect(object)

@export var quest: Quest: set = set_quest

@onready var breadcrumb := %Breadcrumb

func parent_string(q) -> String:
    var accum = ''
    if q.parent:
        accum += "%s > " % parent_string(q.parent)
    accum += q.name
    return accum

func set_quest(new_quest: Quest):
    quest = new_quest
    if not quest:
        breadcrumb.text = ""
        return

    breadcrumb.text = parent_string(quest)

func save():
    pass
