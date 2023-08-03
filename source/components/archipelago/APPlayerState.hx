package components.archipelago;

import haxe.DynamicAccess;
import haxe.Serializer;
import haxe.Unserializer;
import lime.app.Event;
import utilities.DeploymentSchedule;
import components.classic.ClassicPlayerState;

class APPlayerState extends ClassicPlayerState
{
	/**
		Event that fires when the number of Task Advances has changed.
		@param id The sending player's identity string.
		@param newVal The new number of Task Advances.
	**/
	public var onTaskSkipChanged(default, null):Event<(String, Int) -> Void>;

	/**
		Event that fires when the number of Turners has changed.
		@param id The sending player's identity string.
		@param newVal The new number of Turners.
	**/
	public var onTurnerChanged(default, null):Event<(String, Int) -> Void>;

	/**
		Event that fires when the player's level has changed.
		@param id The sending player's identity string.
		@param newVal The new level number.
		@param tasks The list of tasks for this level.
	**/
	public var onLevelChanged(default, null):Event<(String, Int, Array<APTaskV2>) -> Void>;

	/**
		Event that fires when a task has been cleared.
		@param level The level number related to the cleared task.
		@param type The type of task.
		@param goal The goal achieved.
		@param current The current value for the goal.
	**/
	public var onTaskCleared(default, null) = new Event<(Null<Int>, APTaskType, Int, Int) -> Void>();

	/** The player's current count of Task Advances. **/
	public var taskSkip(default, set) = 0;

	/** The player's current count of Turners. **/
	public var turner(default, set) = 0;

	/** _Read-only._ The player's total score across all boards this level. **/
	public var levelScore(get, never):Int;

	/** _Read-only._ The player's total bumpers sticked across all boards this level. **/
	public var levelBlock(get, never):Int;

	/** _Read-only._ The player's total score across all boards this seed. **/
	public var totalScore(get, never):Int;

	/** _Read-only._ The player's total bumpers sticked across all boards this seed. **/
	public var totalBlock(get, never):Int;

	/** The player's current level. Setting this value will affect the task list.**/
	public var level(default, set):Int;

	/** The player's current list of tasks. **/
	public var tasks(get, null):Array<APTaskV2>;

	/** The player's current special bumper schedule. **/
	private var _sched:DynamicAccess<DeploymentSchedule>;

	/**
		Whether a level's tasks are being populated.
		If they are, no check will be made to see if the level has been cleared.
	**/
	private var _levelPopulating = false;

	public function new(id:String)
	{
		super(id);
		_bgColorShuffle = true;
	}

	override function init()
	{
		super.init();
		onTaskSkipChanged = new Event<(String, Int) -> Void>();
		onTurnerChanged = new Event<(String, Int) -> Void>();
		onLevelChanged = new Event<(String, Int, Array<APTaskV2>) -> Void>();
		onTaskCleared = new Event<(Null<Int>, APTaskType, Int, Int) -> Void>();
	}

	override function initReg()
	{
		_reg["paint.next"] = 1000;
		_reg["paint.inc"] = 1500;
		_reg["paint.starting"] = 0;
		_reg["turner.starting"] = 0;
		_reg["score.accrued.level"] = 0;
		_reg["score.accured.game"] = 0;
		_reg["block.accrued.level"] = 0;
		_reg["block.accrued.game"] = 0;
	}

	private function set_taskSkip(taskSkip)
	{
		onTaskSkipChanged.dispatch(id, this.taskSkip = taskSkip);
		return this.taskSkip;
	}

	private function set_turner(turner)
	{
		onTurnerChanged.dispatch(id, this.turner = turner);
		return this.turner;
	}

	inline private function get_levelScore()
		return score + _reg["score.accrued.level"];

	inline private function get_levelBlock()
		return block + _reg["block.accrued.level"];

	inline private function get_totalScore()
		return score + _reg["score.accrued.level"] + _reg["score.accrued.game"];

	inline private function get_totalBlock()
		return block + _reg["block.accrued.level"] + _reg["block.accrued.game"];

	private function set_level(level)
	{
		_levelPopulating = true;
		// TODO: set tasks
		switch (this.level = level)
		{
			case x:
				throw 'Invalid level generated (#$x)';
		}
		onLevelChanged.dispatch(id, level, tasks);
		_levelPopulating = false;
		return level;
	}

	inline private function get_tasks()
		return this.tasks.slice(0);

	/**
		Adds a task to the list.
		@param type The type of task.
		@param goal The goal to achieve.
		@param current Optional. The current value for the goal.
		If this is omitted and it is a Score or Clear-based goal, the current value stored by the HUD is used. Otherwise defaults to 0.
	**/
	private function addTask(type:APTaskType, goals:Array<Int>, ?current:Int)
	{
		if (type == LevelHeader && this.tasks.length > 0)
			throw "Only first task may be LevelHeader metatask";

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

		this.tasks.push({
			type: type,
			goals: goals,
			goalIndex: 0,
			current: 0,
		});
		updateTask(type, current);
	}

	/**
		Updates the current value for a task. If the goal for a task has been achieved, `onTaskCleared` will be dispatched.
		If all tasks have been completed, another `onTaskCleared` with `LevelHeader` as the task type will be dispatched to signal this.

		@param type The type of task.
		@param current The current value for the goal.
	**/
	public function updateTask(type:APTaskType, current:Int)
	{
		var tl = this.tasks;

		if (tl.length == 0)
			return;

		for (task in tl)
		{
			if (task.type != type || task.current > current)
				continue;

			task.current = current;
			while (task.current >= task.curGoal && task.goalIndex < task.goalCount)
			{
				onTaskCleared.dispatch(level, task.type, task.curGoal, task.current);
				task.goalIndex++;
			}
			// TODO: this is still handled by the HUD
			// task.uiText.text = task;
		}

		if (!_levelPopulating)
		{
			var levelTask = tl[0];
			if (levelTask.type == LevelHeader && !levelTask.complete && tl.length > 1)
			{
				var allTasksCleared = true;
				for (task in tl.slice(1))
					allTasksCleared = allTasksCleared && task.complete;
				if (allTasksCleared)
				{
					levelTask.current = levelTask.curGoal;
					onTaskCleared.dispatch(level, LevelHeader, levelTask.curGoal, levelTask.curGoal);
				}
			}
		}
	}

	@:keep
	override function hxSerialize(s:Serializer)
	{
		super.hxSerialize(s);
		s.serialize(taskSkip);
		s.serialize(turner);
		s.serialize(level);
		s.serialize(tasks);
	}

	@:keep
	override function hxUnserialize(u:Unserializer)
	{
		super.hxUnserialize(u);
		this.taskSkip = u.unserialize();
		this.turner = u.unserialize();
		this.level = u.unserialize();
		this.tasks = u.unserialize();
	}
}
