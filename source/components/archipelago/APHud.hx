package components.archipelago;

import flixel.ui.FlxButton;
import components.archipelago.APTask;
import components.classic.ClassicHUD;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUIText;
import haxe.DynamicAccess;
import haxe.Exception;
import lime.app.Event;

/** Adds Archipelago-specific elements to the Classic mode HUD. **/
class APHud extends ClassicHUD
{
	/** The total number of points accrued through previous games on this level. **/
	private var _accruedScoreThisLevel = 0;

	/** The total number of points accrued through previous games. **/
	private var _accruedScore = 0;

	/** The total number of bumpers cleared accured through previous games on this level. **/
	private var _accruedBlockThisLevel = 0;

	/** The total number of bumpers cleared accured through previous games. **/
	private var _accruedBlock = 0;

	/** The task list display component. **/
	private var _taskListbox:FlxUIList;

	/** The internal list of tasks to clear. **/
	private var _taskList:Array<APTask> = [];

	private var _turnerButton:FlxButton;

	/** The current number of available Turners. **/
	public var turners(default, set):Int = 0;

	/** The total number of points obtained through games on this level. **/
	public var levelScore(get, never):Int;

	/** The total number of points obtained through all games. **/
	public var totalScore(get, never):Int;

	/** The total number of bumpers cleared through games on this level. **/
	public var levelBlock(get, never):Int;

	/** The total number of bumpers cleared through all games. **/
	public var totalBlock(get, never):Int;

	/** The current task level. **/
	public var level(get, never):Null<Int>;

	/** Event that fires when the Turner button is clicked. **/
	public var onTurnerClick(default, null) = new Event<Void->Void>();

	/**
		Fires when a task has been cleared.
		@param level The level number related to the cleared task.
		@param type The type of task.
		@param goal The goal achieved.
		@param current The current value for the goal.
	**/
	public var onTaskCleared(default, null) = new Event<(Null<Int>, APTaskType, Int, Int) -> Void>();

	public function new()
	{
		super();

		if (_rightSide)
		{
			var more = "+<X>";
			var listy = _blockCounter.y + _blockCounter.height;
			_taskListbox = new FlxUIList(10, listy, [], width - 20, height - listy - 69, more);

			add(_taskListbox);

			_turnerButton = new FlxButton(5, 5, "T:0", () ->
			{
				if (turners > 0)
					onTurnerClick.dispatch();
			});
			_turnerButton.allowSwiping = false;
			_turnerButton.y = height - _pcButton.height - _turnerButton.height - 5;
			add(_pcButton);
		}

		turners = 0;
	}

	function set_turners(turners:Int) {
		var displayTurners = Math.round(Math.min(turners, 9));
		_turnerButton.text = "P:" + displayTurners;
		_turnerButton.alive = turners > 0;

		return this.turners = turners;
	}

	inline function get_levelScore()
		return _accruedScoreThisLevel + score;

	inline function get_totalScore()
		return _accruedScore + score;

	inline function get_levelBlock()
		return _accruedBlockThisLevel + block;

	inline function get_totalBlock()
		return _accruedBlock + block;

	override function set_score(score:Int):Int
	{
		var retval = super.set_score(score);
		updateTask(Score, retval);
		updateTask(LevelScore, levelScore);
		updateTask(TotalScore, totalScore);
		return retval;
	}

	override function set_block(block:Int):Int
	{
		var retval = super.set_block(block);
		updateTask(Cleared, retval);
		updateTask(LevelCleared, levelBlock);
		updateTask(TotalCleared, totalBlock);
		return retval;
	}

	function get_level():Null<Int>
	{
		if (_taskList.length == 0)
			return null;
		if (_taskList[0].type != LevelHeader)
			return null;
		return _taskList[0].curGoal;
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
				case LevelScore: levelScore;
				case TotalScore: totalScore;
				case Cleared: block;
				case LevelCleared: levelBlock;
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
		if (_taskList.length == 0)
			return;

		for (task in _taskList)
		{
			if (task.type != type || task.current > current)
				continue;

			var wasComplete = task.complete;
			task.current = current;
			if ((!task.complete && task.current >= task.curGoal) || (!wasComplete && task.complete))
			{
				onTaskCleared.dispatch(level, task.type, task.curGoal, task.current);
				if (!task.complete)
					task.goalIndex++;
			}
			task.uiText.text = _t('game/ap/task/$type', ["current" => current, "goal" => task.curGoal]);
		}

		var levelTask = _taskList[0];
		if (levelTask.type == LevelHeader && !levelTask.complete && _taskList.length > 1)
		{
			var allTasksCleared = true;
			for (task in _taskList.slice(1))
				allTasksCleared = allTasksCleared && task.complete;
			if (allTasksCleared)
			{
				levelTask.current = levelTask.curGoal;
				onTaskCleared.dispatch(level, LevelHeader, levelTask.curGoal, levelTask.curGoal);
			}
		}
	}

	/** Removes all tasks from the task list. **/
	public function wipeTasks()
	{
		_taskListbox.clear();
		for (task in _taskList)
			task.uiText.destroy();
		_taskList = [];
		_accruedScoreThisLevel = _accruedBlockThisLevel = 0;
	}

	/** Resets the HUD to its starting values. For Archipelago games, it will also increment `_accruedScore` and `_accruedBlock`. **/
	public override function resetHUD()
	{
		_accruedScoreThisLevel += score;
		_accruedBlockThisLevel += block;
		_accruedScore += score;
		_accruedBlock += block;
		super.resetHUD();
	}

	public override function serialize():DynamicAccess<Dynamic>
	{
		var retval = super.serialize();

		retval["turners"] = turners;
		retval["accScore"] = _accruedScore;
		retval["accScoreTL"] = _accruedScoreThisLevel;
		retval["accBlock"] = _accruedBlock;
		retval["accBlockTL"] = _accruedBlockThisLevel;
		retval["tasks"] = _taskList.map(t -> t.serialize());

		return retval;
	}
}
