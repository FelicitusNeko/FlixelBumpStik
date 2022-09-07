package components.archipelago;

import components.archipelago.APTask;
import components.classic.ClassicHUD;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;
import haxe.Exception;
import lime.app.Event;

/** Adds Archipelago-specific elements to the Classic mode HUD. **/
class APHud extends ClassicHUD
{
	/** The total number of points accrued through previous games. **/
	private var _accruedScore = 0;

	/** The total number of bumpers cleared accured through previous games. **/
	private var _accruedBlock = 0;

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
		return _accruedScore + score;

	inline function get_totalBlock()
		return _accruedBlock + block;

	override function set_score(score:Int):Int
	{
		var retval = super.set_score(score);
		updateTask(Score, retval);
		updateTask(TotalScore, totalScore);
		return retval;
	}

	override function set_block(block:Int):Int
	{
		var retval = super.set_block(block);
		updateTask(Cleared, retval);
		updateTask(TotalCleared, totalBlock);
		return retval;
	}

	/**
		Adds a task to the list.
		@param type The type of task.
		@param goal The goal to achieve.
		@param current Optional. The current value for the goal.
		If this is omitted and it is a Score or Clear-based goal, the current value stored by the HUD is used. Otherwise defaults to 0.
	**/
	public function addTask(type:APTaskType, goals:Array<Int>, ?current:Int)
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
			goals: goals,
			goalIndex: 0,
			current: 0,
			uiText: new FlxUIText(0, 0, 0, _t('game/ap/task/$type', ["current" => current, "goal" => goals[0]]))
		};
		if (type == LevelHeader)
		{
			newTask.uiText.size += 4;
			newTask.uiText.alignment = CENTER;
		}
		_taskList.push(newTask);
		updateTask(type, current);
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

			var wasComplete = task.complete;
			task.current = current;
			if ((!task.complete && task.current >= task.curGoal) || (!wasComplete && task.complete))
			{
				onTaskCleared.dispatch(task.type, task.curGoal, task.current);
				if (!task.complete)
					task.goalIndex++;
			}
			task.uiText.text = _t('game/ap/task/$type', ["current" => current, "goal" => task.curGoal]);
		}

		var allTasksCleared = true;
		for (task in _taskList)
			allTasksCleared = allTasksCleared && (task.type == LevelHeader ? true : task.complete);
		if (allTasksCleared)
		{
			var levelTask = _taskList[0];
			if (levelTask.type == LevelHeader)
			{
				levelTask.uiText.color = FlxColor.GREEN;
				onTaskCleared.dispatch(LevelHeader, levelTask.curGoal, levelTask.curGoal);
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

	/** Resets the HUD to its starting values. For Archipelago games, it will also increment `_accruedScore` and `_accruedBlock`. **/
	override public function resetHUD()
	{
		_accruedScore += score;
		_accruedBlock += block;
		super.resetHUD();
	}
}
