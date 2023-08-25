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
		@param id The sending player's identity string.
		@param level The level number related to the cleared task.
		@param type The type of task.
		@param goal The goal achieved.
		@param current The current value for the goal.
	**/
	public var onTaskCleared(default, null):Event<(String, Null<Int>, APTaskType, Int, Int) -> Void>;

	/**
		Event that fires when a Hazard Bumper needs to be deployed.
		@param id The sending player's identity string.
	**/
	public var onDeployHazard(default, null):Event<String->Void>;

	public var boardSize(get, never):{w:Int, h:Int};

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

	/** Initializes things like event handlers. **/
	override function init()
	{
		super.init();
		onTaskSkipChanged = new Event<(String, Int) -> Void>();
		onTurnerChanged = new Event<(String, Int) -> Void>();
		onLevelChanged = new Event<(String, Int, Array<APTaskV2>) -> Void>();
		onTaskCleared = new Event<(String, Null<Int>, APTaskType, Int, Int) -> Void>();
		onDeployHazard = new Event<String->Void>();
	}

	/** Initializes the value registry. **/
	override function initReg()
	{
		super.initReg();
		_reg["board.w"] = 3;
		_reg["board.h"] = 3;
		_reg["color.next"] = 50;
		_reg["color.step"] = 50;
		_reg["color.start"] = 2;
		_reg["color.max"] = 3;
		_reg["paint.next"] = 1000;
		_reg["paint.inc"] = 1500;
		_reg["paint.starting"] = 0;
		_reg["turner.starting"] = 0;
		_reg["score.accrued.level"] = 0;
		_reg["score.accured.game"] = 0;
		_reg["block.accrued.level"] = 0;
		_reg["block.accrued.game"] = 0;
	}

	inline private function get_boardSize()
		return {
			w: _reg["board.w"],
			h: _reg["board.h"]
		};

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
		_reg["score.accrued.game"] += _reg["score.accrued.level"];
		_reg["block.accrued.game"] += _reg["block.accrued.level"];
		_reg["score.accrued.level"] = _reg["block.accrued.level"] = 0;

		this.tasks = [];
		if (level > 0)
			addTask(LevelHeader, [level]);

		switch (this.level = level)
		{
			case 1:
				_reg["board.w"] = _reg["board.h"] = 3;
				_reg["color.start"] = 2;
				_reg["color.max"] = 3;
				_reg["color.next"] = _reg["color.step"] = 50;
				addTask(Score, [250, 500, 750, 1000]);
				addTask(LevelScore, [500, 1000, 1500, 2000]);
				addTask(LevelCleared, [for (x in 1...4) x * 25]);
				addTask(Combo, [5]);
				addTask(Boosters, [1], _sched["booster"].clear);
				addTask(Treasures, [8], _sched["treasure"].clear);
				_sched["booster"].maxAvailable = 2;
				_sched["treasure"].maxAvailable = 9;
				_sched["hazard"].maxAvailable = 0;

			case 2:
				_reg["board.w"] = _reg["board.h"] = 4;
				_reg["color.start"] = 2;
				_reg["color.max"] = 4;
				_reg["color.next"] = 25;
				_reg["color.step"] = 50;
				addTask(Score, [500, 1000, 1500, 2000]);
				addTask(LevelScore, [1000, 2000, 3000, 4000]);
				addTask(LevelCleared, [for (x in 1...5) x * 25]);
				addTask(Combo, [5]);
				addTask(Chain, [2]);
				addTask(Boosters, [2], _sched["booster"].clear);
				addTask(Treasures, [16], _sched["treasure"].clear);
				_sched["booster"].maxAvailable = 3;
				_sched["treasure"].maxAvailable = 17;
				_sched["hazard"].setDelay(10, 25);
				_sched["hazard"].maxAvailable = 3;

			case 3:
				_reg["board.w"] = 5;
				_reg["board.h"] = 4;
				_reg["color.start"] = 3;
				_reg["color.max"] = 5;
				_reg["color.next"] = _reg["color.step"] = 50;
				addTask(Score, [800, 1600, 2400, 3200]);
				addTask(LevelScore, [2000, 4000, 6000, 8000]);
				addTask(LevelCleared, [for (x in 1...6) x * 25]);
				addTask(Combo, [5, 7]);
				addTask(Chain, [2]);
				addTask(AllClear, [3]);
				addTask(Boosters, [3], _sched["booster"].clear);
				addTask(Treasures, [24], _sched["treasure"].clear);
				_sched["booster"].maxAvailable = 4;
				_sched["treasure"].maxAvailable = 25;
				_sched["hazard"].setDelay(5, 20);
				_sched["hazard"].maxAvailable = 8;

			case 4:
				_reg["board.w"] = _reg["board.h"] = 5;
				_reg["color.start"] = 3;
				_reg["color.max"] = 6;
				_reg["color.next"] = _reg["color.step"] = 75;
				addTask(Score, [1500, 3000, 4500, 6000]);
				addTask(LevelScore, [3000, 6000, 9000, 12000]);
				addTask(LevelCleared, [for (x in 1...7) x * 25]);
				addTask(Combo, [5, 7]);
				addTask(Chain, [2, 3]);
				addTask(Boosters, [5], _sched["booster"].clear);
				addTask(Treasures, [32], _sched["treasure"].clear);
				_sched["booster"].maxAvailable = 5;
				_sched["treasure"].maxAvailable = 999;
				_sched["hazard"].setDelay(3, 15);
				_sched["hazard"].maxAvailable = 15;

			case 5:
				_reg["board.w"] = _reg["board.h"] = 6;
				_reg["color.start"] = 4;
				_reg["color.max"] = 6;
				_reg["color.next"] = _reg["color.step"] = 100;
				addTask(TotalScore, [Math.round(Math.max(50000, totalScore + 5000))]);
				addTask(Hazards, [25], _sched["hazard"].clear);
				_sched["hazard"].setDelay(1, 10);
				for (s in _sched)
					s.maxAvailable = 999;

			case 6 | -1:
			// this will finish the game
			// game state will handle this when onLevelChanged is called
			// just handling the state so it doesn't fall through into throw

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
				onTaskCleared.dispatch(id, level, task.type, task.curGoal, task.current);
				task.goalIndex++;
			}
			// TODO: this is still to be handled by the HUD
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
					onTaskCleared.dispatch(id, level, LevelHeader, levelTask.curGoal, levelTask.curGoal);
				}
			}
		}
	}

	/** Resets the player state. **/
	override function reset()
	{
		_reg["score.accrued.level"] += score;
		_reg["block.accrued.level"] += block;
		super.reset();
		for (sch in _sched)
			sch.reset();
	}

	/** Saves the player state to text via Haxe's `Serializer`. **/
	@:keep
	override function hxSerialize(s:Serializer)
	{
		super.hxSerialize(s);
		s.serialize(taskSkip);
		s.serialize(turner);
		s.serialize(level);
		s.serialize(tasks);
	}

	/** Restores the player state from text via Haxe's `Unserializer`. **/
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
