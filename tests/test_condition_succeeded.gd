extends GutTest

var ExampleAction = load("res://tests/fake_task_action.gd")

func test_succeed_sets_value_true():
    var c = TaskCondition.new()
    assert_false(c.passed)

    c.succeed()
    assert_true(c.passed)

func test_succeed_executes_actions():
    var c = TaskCondition.new()
    var a = ExampleAction.new()
    c.add_action(a)

    assert_false(bool(a.executed))
    c.succeed()
    assert_true(bool(a.executed))

func test_succeed_only_executes_actions_once():
    var c = TaskCondition.new()
    var a = ExampleAction.new()
    c.add_action(a)

    assert_eq(a.executed, 0)
    c.succeed()
    c.succeed()
    c.succeed()
    assert_eq(a.executed, 1)
