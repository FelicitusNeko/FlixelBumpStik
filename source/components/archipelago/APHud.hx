package components.archipelago;

import components.classic.ClassicHUD;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;
import haxe.Exception;
import lime.app.Event;

/** The type of task to be completed. **/
enum APTaskType
{
	/** The pseudotask at the top of the list to indicate the current level. **/
	LevelHeader;

	/** A certain number of points must be obtained this game. **/
	Score;

	/** A certain number of points must be obtained across all games this session. **/
	TotalScore;

	/** A certain number of bumpers must be cleared this game. **/
	Cleared;

	/** A certain number of bumpers must be cleared across all games this session. **/
	TotalCleared;

	/** A combo of a certain number of bumpers must be formed. **/
	Combo;

	/** A chain of a certain length must be formed. **/
	Chain;

	/** A certain number of Treasure Bumpers must be cleared across all games this session. **/
	Treasures;

	/** A certain number of Bonus Boosters must be cleared across all games this session. **/
	Boosters;

	/** A certain number of Hazard Bumpers must be cleared across all games this session. **/
	Hazards;

	/** An All Clear must be obtained with at least a certain number of colors. **/
	AllClear;
}

/** The definition for an Archipelago check task. **/
typedef APTask =
{
	/** The type of task. **/
	var type:APTaskType;

	// TODO: rolling goals, to have a task that has multiple goals for multiple checks

	/** The current goal number for this task. **/
	var goal:Int;

	/** The current number achieved for this task. **/
	var current:Int;

	/** Whether this task has been marked as complete. **/
	var complete:Bool;

	/** The UI text for the task list. **/
	var uiText:FlxUIText;
}

/** Adds Archipelago-specific elements to the Classic mode HUD. **/
class APHud extends ClassicHUD
{
	/** The total number of points accrued through previous games. **/
	private var _totalScore = 0;

	/** The total number of bumpers cleared accured through previous games. **/
	private var _totalBlock = 0;

	/** The task list display component. **/
	private var _taskListbox:FlxUIList;

	/** The internal list of tasks to clear. **/
	private var _taskList:Array<APTask> = [];

	/** The total number of points obtained through all games. **/
	public var totalScore(get, never):Int;

	/** The total number of bumpers cleared through all games. **/
	public var totalBlock(get, never):Int;

	/**
		Fires when a task has been cleared.
		@param type The type of task.
		@param goal The goal achieved.
		@param current The current value for the goal.
	**/
	public var onTaskCleared(default, null) = new Event<(APTaskType, Int, Int) -> Void>();

	public function new()
	{
		super();

		if (_rightSide)
		{
			var more = "+<X>";
			var listy = _blockCounter.y + _blockCounter.height;
			_taskListbox = new FlxUIList(10, listy, [], width - 20, height - listy - 69, more);

			add(_taskListbox);
		}
	}

	inline function get_totalScore()
		return _totalScore + score;

	inline function get_totalBlock()
		return _totalBlock + block;

	/**
		Adds a task to the list.
		@param type The type of task.
		@param goal The goal to achieve.
		@param current Optional. The current value for the goal.
		If this is omitted and it is a Score or Clear-based goal, the current value stored by the HUD is used. Otherwise defaults to 0.
	**/
	public function addTask(type:APTaskType, goal:Int, ?current:Int)
	{
		if (type == LevelHeader && _taskList.length > 0)
			throw new Exception("Only first task may be Level pseudotask");

		if (current == null)
			current = switch (type)
			{
				case Score: score;
				case TotalScore: totalScore;
				case Cleared: block;
				case TotalCleared: totalBlock;
				default: 0;
			}
		var newTask:APTask = {
			type: type,
			goal: goal,
			current: current,
			complete: current >= goal,
			uiText: new FlxUIText(0, 0, 0, _t('game/ap/task/$type', ["current" => current, "goal" => goal]))
		}
		if (type == LevelHeader)
		{
			newTask.uiText.size += 4;
			newTask.uiText.alignment = CENTER;
		}
		if (newTask.complete)
		{
			newTask.uiText.color = FlxColor.GREEN;
			onTaskCleared.dispatch(newTask.type, newTask.goal, newTask.current);
		}
		_taskList.push(newTask);
		_taskListbox.add(newTask.uiText);
	}

	/**
		Updates the current value for a task. If the goal for a task has been achieved, `onTaskCleared` will be dispatched.
		If all tasks have been completed, another `onTaskCleared` will be dispatched to signal this.

		@param type The type of task.
		@param current The current value for the goal.
	**/
	public function updateTask(type:APTaskType, current:Int)
	{
		for (task in _taskList)
		{
			if (task.type != type || task.current > current)
				continue;

			task.current = current;
			if (!task.complete && (task.complete = task.complete || (task.current >= task.goal)))
			{
				task.uiText.color = FlxColor.GREEN;
				onTaskCleared.dispatch(task.type, task.goal, task.current);
			}
		}

		var allTasksCleared = true;
		for (task in _taskList)
			allTasksCleared = allTasksCleared && (task.type == LevelHeader ? true : task.complete);
		if (allTasksCleared)
		{
			var levelTask = _taskList[0];
			if (levelTask.type == LevelHeader)
			{
				levelTask.complete = true;
				levelTask.uiText.color = FlxColor.GREEN;
				onTaskCleared.dispatch(LevelHeader, levelTask.goal, levelTask.goal);
			}
		}
	}

	/** Removes all tasks from the task list. **/
	public function wipeTasks()
	{
		while (_taskList.pop() != null) {}
		for (task in _taskListbox.group)
		{
			_taskListbox.remove(task);
			task.destroy();
		}
	}

	/** Resets the HUD to its starting values. For Archipelago games, it will also increment `_totalScore` and `_totalBlock`. **/
	override public function resetHUD()
	{
		_totalScore += score;
		_totalBlock += block;
		super.resetHUD();
	}
}
