# meta-default: true
@tool
@icon("res://addons/tmc_quest/assets/condition_icon.svg")
class_name _CLASS_QuestCondition
extends QuestCondition

const name := "_CLASS_"
const description := "Describe your condition"

func _check() -> bool:
    # implement your condition checking logic here
    # return true if your condition has been met
    return passed

func _activated():
    # anything you need to do when activated (e.g. connect a signal)
    pass

func _deactivated():
    # anything you need to do when deactivated (e.g. disconnect a signal)
    pass
