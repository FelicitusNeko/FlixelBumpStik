package components.archipelago;

import haxe.DynamicAccess;
import haxe.Exception;
import haxe.Serializer;
import haxe.Unserializer;
import ap.PacketTypes;
import boardObject.Bumper;
import boardObject.archipelago.APHazardPlaceholder;
import flixel.FlxG;
import flixel.math.FlxRandom;
import lime.app.Event;
import utilities.DeploymentSchedule;
import components.archipelago.APDefinitions;
import components.classic.ClassicPlayerState;
import components.common.CommonBoard;

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
		Event that fires when a task is updated.
		@param id The sending player's identity string.
		@param index The index of the task to be updated.
		@param task The task to be updated.
	**/
	public var onTaskUpdated(default, null):Event<(String, Int, APTaskV2) -> Void>;

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

	/** The player's current board, as an `APBoard`. **/
	public var apBoard(get, never):APBoard;

	/** The size of the current board, in board object units. **/
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

	/** The schedule randomiser for this multiworld. **/
	private var _rng = new FlxRandom();

	/**
		Whether a level's tasks are being populated.
		If they are, no check will be made to see if the level has been cleared.
	**/
	private var _levelPopulating = false;

	// !------------------------- INSTANTIATION

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
		onTaskUpdated = new Event<(String, Int, APTaskV2) -> Void>();
		onTaskCleared = new Event<(String, Null<Int>, APTaskType, Int, Int) -> Void>();
		onDeployHazard = new Event<String->Void>();

		addRule({
			name: "gameComplete",
			condition: If(() -> level >= 6),
			execute: Process(() ->
			{
				// TODO: send complete to server
				return Signal("ap-complete");
			}),
			priority: 5
		});
		addRule({
			name: "levelComplete",
			condition: If(() ->
			{
				for (task in tasks)
					if (!task.complete)
						return false;
				return true;
			}),
			execute: Process(() ->
			{
				FlxG.sound.play(AssetPaths.levelup__wav);
				apBoard.levelClear();
				return Signal("ap-lvcomplete");
			}),
			priority: 20
		});
		addRule({
			name: "allClearAP",
			condition: If(() -> (board.bCount == 0 && _reg["jackpot"] > 0)),
			execute: Execute(() -> updateTask(AllClear, _bg.colors)),
			priority: 39
		});
	}

	/** Initializes the value registry. **/
	override function initReg()
	{
		super.initReg();
		_reg["board.w"] = 3;
		_reg["board.h"] = 3;
		_reg["color.next"] = 50;
		_reg["color.next.start"] = 50;
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
		_reg["ap.last"] = -1;
		_reg["ap.slot"] = -1;
	}

	// !------------------------- PROPERTY HANDLERS

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

	inline private function get_apBoard()
		return cast(board, APBoard);

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
				_reg["color.next"] = _reg["color.next.start"] = _reg["color.step"] = 50;
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
				_reg["color.next"] = _reg["color.next.start"] = 25;
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
				_reg["color.next"] = _reg["color.next.start"] = _reg["color.step"] = 50;
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
				_reg["color.next"] = _reg["color.next.start"] = _reg["color.step"] = 75;
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
				_reg["color.next"] = _reg["color.next.start"] = _reg["color.step"] = 100;
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
				throw new Exception(_t("game/ap/error/levelgen", ["level" => level]));
		}

		onLevelChanged.dispatch(id, level, tasks);

		_levelPopulating = false;
		return level;
	}

	inline private function get_tasks()
		return this.tasks.slice(0);

	// !------------------------- METHODS

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

		for (x => task in tl)
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

			onTaskUpdated.dispatch(id, x, task);
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

	public function loadTaskSkip(dlg:TaskSkipSubstate)
		dlg.loadTasksV2(tasks.slice(1).filter(i -> !i.complete));

	// !------------------------- EVENT HANDLERS

	/**
		Called by AP client when an item is received.
		@param items Items that have been received.
	**/
	private function onItemsReceived(items:Array<NetworkItem>)
	{
		// if (_ap.clientStatus != ClientStatus.PLAYING)
		// 	_itemBuffer = _itemBuffer.concat(items);
		// else
		for (itemObj in items.filter(i -> i.index > _reg["ap.last"]))
		{
			var item:APItem = itemObj.item;
			if (item == Nothing)
				continue;

			// trace("Item received: " + item);
			var substitutes:Map<String, Dynamic> = [];
			switch (item)
			{
				case ScoreBonus:
					var bonus = 200 * Math.round(Math.pow(2, level - 1));
					score += bonus;
					substitutes.set("bonus", bonus);
				case TaskSkip:
					taskSkip++;
				case StartingTurner:
					_reg["turner.starting"]++;
					turner++;
				// case Blank004:
				// this shouldn't happen currently
				case StartPaintCan:
					_reg["paint.starting"]++;
					paint++;
				case BonusBooster:
					_sched["booster"].inStock++;
				case HazardBumper:
					_sched["hazard"].inStock++;
				case TreasureBumper:
					_sched["treasure"].inStock++;
				case RainbowTrap:
					apBoard.trapTrigger = Rainbow(_bg.colorsInPlay);
				case SpinnerTrap:
					apBoard.trapTrigger = Spinner;
				case KillerTrap:
					apBoard.trapTrigger = Killer;
				case x:
					substitutes.set("id", x);
					trace('Unknown item ID received: ${itemObj.item}');
			}
			// pushToast(_t("game/ap/received", ["item" => Std.string(_t(item, substitutes))]),
			// 	[RainbowTrap, SpinnerTrap, KillerTrap].contains(item) ? FlxColor.ORANGE : FlxColor.CYAN);

			_reg["ap.last"] = itemObj.index;
		}
	}

	// !------------------------- OVERRIDES

	/**
		Creates a new board.
		@param force Create a board even if one is present and in progress. Default `false`.
	**/
	override function createBoard(force:Bool = false)
	{
		if (force || board == null || board.state == "gameover")
		{
			if (board != null)
				detachBoard();
			if (level < 1 || level > 5)
				board = null;
			else
				board = new APBoard(0, 0, _reg["board.w"], _reg["board.h"]);
			attachBoard();
		}
	}

	/**
		Modifies a bumper.
		@param b The bumper to modify.
		@return The modified bumper. If not overridden, `b` is returned as-is.
	**/
	override function modifyBumper(b:Bumper):Bumper
	{
		for (key => schedule in _sched)
		{
			if (schedule.inStock <= 0 || schedule.available <= 0)
				continue;
			if (++schedule.sinceLast < schedule.minDelay)
				continue;
			if (b.flairCount > 0 && key != "hazard")
				continue;
			if (schedule.sinceLast >= schedule.maxDelay || _rng.bool(schedule.eligibleTurns / schedule.maxEligible * 100))
			{
				schedule.sinceLast = 0;
				schedule.inStock--;
				schedule.onBoard++;
				switch (key)
				{
					case "treasure":
						b.addFlair("treasure");
					case "booster":
						b.addFlair("booster");
					case "hazard":
						var emptyPos = board.getRandomSpace(true);
						if (emptyPos != null)
							board.putObstacleAt(emptyPos[0], emptyPos[1], new APHazardPlaceholder(0, 0, _bg.generateColor(true), board));
						onDeployHazard.dispatch(id);
				}
			}
		}
		return b;
	}

	override function onMatch(chain:Int, combo:Int, bumpers:Array<Bumper>)
	{
		updateTask(Chain, chain);
		updateTask(Combo, combo);

		for (b in bumpers)
			if (b.hasFlair("booster"))
				multiStack[1] += .2;

		super.onMatch(chain, combo, bumpers);
	}

	override function onClear(chain:Int, bumper:Bumper)
	{
		for (key => sched in _sched)
			if (bumper.hasFlair(key))
			{
				sched.clear++;
				sched.onBoard--;
				switch (key)
				{
					case "treasure":
						// TODO: report treasure clear to game state
						chain++;
						updateTask(Treasures, sched.clear);
					case "booster":
						// TODO: report booster clear to game state
						updateTask(Boosters, sched.clear);
					case "hazard":
						updateTask(Hazards, sched.clear);
				}
			}
		super.onClear(chain, bumper);
	}

	/** Resets the player state. **/
	override function reset()
	{
		_reg["score.accrued.level"] += score;
		_reg["block.accrued.level"] += block;

		if (level == 0 || tasks.length == 0 || (tasks[0].type == LevelHeader && tasks[0].complete))
			level++;

		super.reset();

		if (level < 6)
		{
			multiStack = [.4 + (_bg.colors * .2), 1.0 + (_sched["booster"].clear * .2)];
			_bg.colorLimit = _reg["color.max"];
			_bg.colors = _reg["color.start"];
			_reg["color.next"] = _reg["color.next.start"];

			paint = _reg["paint.starting"];
			turner = 0;
			turner = _reg["turner.starting"];

			for (sch in _sched)
				sch.reset();
		}
	}

	/** Saves the player state to text via Haxe's `Serializer`. **/
	@:keep
	override function hxSerialize(s:Serializer)
	{
		super.hxSerialize(s);
		s.serialize(_rng.initialSeed);
		s.serialize(_rng.currentSeed);
		s.serialize(taskSkip);
		s.serialize(turner);
		s.serialize(level);
		s.serialize(tasks);
	}

	// TODO: make boards hxSerializable

	/** Loads the board data. **/
	override function deserializeBoard(data:DynamicAccess<Dynamic>):CommonBoard
	{
		var boardData:DynamicAccess<Dynamic> = data["board"];
		var board = new APBoard(0, 0, boardData["width"], boardData["height"]);
		board.deserialize(data);
		return board;
	}

	/** Restores the player state from text via Haxe's `Unserializer`. **/
	@:keep
	override function hxUnserialize(u:Unserializer)
	{
		super.hxUnserialize(u);
		_rng = new FlxRandom(u.unserialize());
		_rng.currentSeed = u.unserialize();
		this.taskSkip = u.unserialize();
		this.turner = u.unserialize();
		this.level = u.unserialize();
		this.tasks = u.unserialize();
	}
}
