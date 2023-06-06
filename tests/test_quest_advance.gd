extends GutTest

var ExampleCondition = load("res://tests/fake_quest_condition.gd")

var quest: Quest

func before_each():
    quest = Quest.new()

func test_advance_checks_own_conditions():
    var c = ExampleCondition.new()
    quest.add_condition(c)
    quest.activate()

    assert_false(bool(c.checked))
    quest.advance()
    assert_true(bool(c.checked))

func test_advance_checks_conditions_of_subs():
    var t1 = Quest.new()
    t1.activate()

    quest.add_subquest(t1)
    quest.activate()

    var c = ExampleCondition.new()
    t1.add_condition(c)

    quest.advance()
    assert_true(bool(c.checked))

func test_advance_inactive_quest_does_not_checks_conditions_of_or_subs():
    var t1 = Quest.new()
    t1.activate()
    quest.add_subquest(t1)

    var c = ExampleCondition.new()
    quest.add_condition(c)

    var c1 = ExampleCondition.new()
    t1.add_condition(c1)

    quest.advance()
    assert_false(bool(c.checked))
    assert_false(bool(c1.checked))
