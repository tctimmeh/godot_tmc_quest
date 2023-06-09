# meta-default: true
@tool
@icon("res://addons/tmc_quest/assets/condition_icon.svg")
class_name _CLASS_QuestCondition
extends QuestCondition

const name := "_CLASS_"

func check():
    # implement your condition checking logic here
    return false

func activate():
    super()
    # anything you need to do when activated (e.g. connect a signal)

func deactivate():
    super()
    # anything you need to do when deactivated (e.g. disconnect a signal)
