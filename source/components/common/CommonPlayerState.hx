package components.common;

import haxe.DynamicAccess;
import haxe.Exception;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.ds.ArraySort;
import boardObject.Bumper;
import boardObject.Launcher;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import lime.app.Event;
import components.common.CommonBoard;

/** The condition upon which a rule will be fired. **/
enum TurnCondition
{
	/** Rule is fired only if the result of the function is `true`. **/
	If(f:Void->Bool);

	/** Rule is fired every time. **/
	Always;
}

/** The function to execute if the condition is met. **/
enum TurnExecute
{
	/** Run a function, then continue evaluating rules. **/
	Execute(f:Void->Void);

	/** Run a function, then return a result to the game state. **/
	Process(f:Void->TurnResult);

	/** Return a result to the game state. **/
	Return(r:TurnResult);

	/** Throw an exception. **/
	Throw(s:String);
}

/** The result of calling for next turn. **/
enum TurnResult
{
	/** A bumper has been generated. **/
	Next(b:Bumper);

	/** A substate is to be displayed. **/
	Notice(s:FlxSubState);

	/** Wait for the state to change again. **/
	Standby;

	/** Wait `msec` milliseconds before calling nextTurn() again. **/
	Wait(msec:Int);

	/** The game is over. **/
	Kill;

	/** A custom function is to be called. **/
	Custom(f:Void->Void);
}

/** A definition for a rule to be checked when `nextTurn()` is called. **/
typedef RuleDefinition =
{
	/** The name of the rule, for later reference. **/
	var name:String;

	/** The rule's priority. Closer to 0 gets executed first. **/
	var priority:Int;

	/** The condition upon which the rule is fired. **/
	var condition:TurnCondition;

	/** The function to execute if the condition is met. **/
	var execute:TurnExecute;

	/** Whether the rule is disabled and will not be checked. **/
	var ?disabled:Bool;
}

/** Base class to keep the state of a player. **/
abstract class CommonPlayerState
{
	//-------- EVENTS

	/** Event that fires when score changes. **/
	public var onScoreChanged(default, null):Event<(String, Int) -> Void>;

	/** Event that fires when bumpers sticked count changes. **/
	public var onBlockChanged(default, null):Event<(String, Int) -> Void>;

	/** Event that fires when a bonus is awarded. **/
	public var onBonus(default, null):Event<(String, Int) -> Void>;

	/** Event that fires when a bumper is launched. **/
	public var onLaunch(default, null):Event<(String, Bumper) -> Void>;

	/** Event that fires when the next bumper changes. **/
	public var onNextChanged(default, null):Event<(String, Bumper) -> Void>;

	/** Event that fires when the board's state changes. **/
	public var onBoardStateChanged(default, null):Event<(String, String) -> Void>;

	//-------- PROPERTIES

	/** _Read-only._ The ID for this player.**/
	public var id(default, null):String;

	/** The player's current board. **/
	public var board(default, null):CommonBoard;

	/** The player's current score. **/
	public var score(default, set) = 0;

	/** The player's current count of cleared bumpers. **/
	public var block(default, set) = 0;

	/** The player's current count of launched bumpers. **/
	public var launched(default, null) = 0;

	/** The player's current next bumper. **/
	public var next(default, set):Bumper = null;

	/** The player's current multiplier stack. Points added via `addScore()` will have these values multiplied to it. If empty or `null`, points will be added as-is. **/
	public var multiStack(get, default) = [1.0];

	//-------- MEMBER DATA

	/** The player's bumper generator. **/
	private var _bg:BumperGenerator;

	/** Determines whether colors will be shuffled when `reset()` is called. **/
	private var _bgColorShuffle = false;

	/** The default multiplier stack. The multiplier stack will be set to this when `reset()` is called. **/
	private var _dfltMultiStack = [1.0];

	/** Registry of values. **/
	private var _reg:DynamicAccess<Int>;

	/** Rules to be processed on `runNextTurn()` **/
	private var _rules:Array<RuleDefinition>;

	//-------- CODE

	/** Creates a new player state **/
	public function new(id:String)
	{
		this.id = id;
		_reg = {};
		init();
		initReg();
	}

	/** Initializes things like event handlers. **/
	private function init()
	{
		onScoreChanged = new Event<(String, Int) -> Void>();
		onBlockChanged = new Event<(String, Int) -> Void>();
		onBonus = new Event<(String, Int) -> Void>();
		onLaunch = new Event<(String, Bumper) -> Void>();
		onNextChanged = new Event<(String, Bumper) -> Void>();
		onBoardStateChanged = new Event<(String, String) -> Void>();

		addRule({
			name: "noTurnWithoutGenerator",
			condition: If(() -> _bg == null),
			execute: Throw("Turn advanced without generator present"),
			priority: 10
		});
		addRule({
			name: "fallbackNext",
			condition: Always,
			execute: Process(() -> Next(generateBumper())),
			priority: 100
		});
	}

	/** _Abstract._ Initializes the value registry. **/
	abstract function initReg():Void;

	private function set_score(score)
	{
		onScoreChanged.dispatch(id, this.score = score);
		return this.score;
	}

	private function set_block(block)
	{
		onBlockChanged.dispatch(id, this.block = block);
		return this.block;
	}

	private function set_next(next)
	{
		onNextChanged.dispatch(id, this.next = next);
		return this.next;
	}

	private inline function get_multiStack()
	{
		if (multiStack == null)
			return [];
		return multiStack.slice(0);
	}

	/**
		Launches the current bumper in stock.
		@param l The Launcher to launch from.
	**/
	public function launch(l:Launcher)
	{
		l.launchBumper(next);
		onLaunch.dispatch(id, next);
		next = null;
		launched++;
	}

	/**
		Sets an individual value in the multiplier stack. Quietly fails if `pos` is out of range.
		@param pos The multiplier value to set.
		@param val The new value to set in the given position.
	**/
	public inline function setMultiStackValue(pos:Int, val:Float)
		if (pos >= 0 && pos < multiStack.length)
			multiStack[pos] = val;

	/**
		Adds to the score based on the multiplier stack.
		@param add The amount of points to be multiplied and added.
		@param isBonus _Optional._ Whether the score being added is a bonus. Default `false`.
		@return The final amount of points being added.
	**/
	public function addScore(add:Int, isBonus = false)
	{
		var newAdd = add;

		if (add > 0 && multiStack != null && multiStack.length > 0)
		{
			var addF:Float = add;
			for (x in multiStack)
				addF *= x;
			newAdd = Math.round(addF);
		}

		if (isBonus)
			onBonus.dispatch(id, add);

		score += newAdd;
		return newAdd;
	}

	/**
		Creates a bumper generator.
		@param initColors The number of colors to start with. Defaults to 3.
		@param colorSet The set of colors to use. Defaults to the standard Bumper Stickers palette.
	**/
	public function createGenerator(initColors = 3, ?colorSet:Array<FlxColor>)
	{
		_bg = new BumperGenerator(initColors, colorSet);
		if (_bgColorShuffle)
			_bg.shuffleColors();
	}

	/**
		_Abstract._ Creates a new board.
		@param force Create a board even if one is present and in progress.
	**/
	abstract public function createBoard(force:Bool = false):Void;

	/** Attaches the player state to its board's events. **/
	function attachBoard()
	{
		board.onBoardStateChanged.add(onInnerBoardStateChanged);
		board.onMatch.add(onMatch);
		board.onClear.add(onClear);
		board.onLaunchBumper.add(onLaunchSelect);
	}

	/** Detaches the player state from its board's events. **/
	function detachBoard()
	{
		board.onBoardStateChanged.remove(onInnerBoardStateChanged);
		board.onMatch.remove(onMatch);
		board.onClear.remove(onClear);
		board.onLaunchBumper.remove(onLaunchSelect);
	}

	/** Forwards onBoardStateChanged events from the board with the player ID. **/
	function onInnerBoardStateChanged(state)
		onBoardStateChanged.dispatch(id, state);

	/**
		Receives match events from the board.
		@param chain The chain valance for this match.
		@param combo The combo number for this event.
		@param bumpers The bumpers involved in this match.
	**/
	function onMatch(chain:Int, combo:Int, _:Array<Bumper>)
	{
		var bonus = ((combo - 3) + (chain - 1)) * Math.floor(Math.pow(2, (chain - 1))) * 50;
		if (chain > 1)
			FlxG.sound.play(AssetPaths.chain__wav);
		else if (combo > 3)
			FlxG.sound.play(AssetPaths.combo__wav);
		else
			FlxG.sound.play(AssetPaths.match__wav);

		addScore(bonus, true);
	}

	/**
		Receives bumper clear events from the board.
		@param chain The chain valance for this clear.
		@param bumper The bumper being cleared.
	**/
	function onClear(chain:Int, _:Bumper)
	{
		FlxG.sound.play(AssetPaths.clear__wav);
		block++;
		addScore(10 * Math.floor(Math.pow(2, chain - 1)));
	}

	/**
		Receives onLauncherSelect events from the board.
		@param cb The bumper to be sent to the Launcher.
	**/
	function onLaunchSelect(cb:BumperCallback) // NOTE: maybe rework how this works
	{
		FlxG.sound.play(AssetPaths.launch__wav);

		var b = next == null ? _bg.weightedGenerate() : next;
		next = null;
		addScore(5);
		cb(b);
	}

	/**
		Adds a next turn rule.
		@param rule The rule to be added.
		@throws Exception Will throw an error if the name used already exists in existing rule definitions.
	**/
	final function addRule(rule:RuleDefinition)
	{
		if (_rules == null)
			_rules = [];
		if (_rules.filter(i -> i.name == rule.name).length > 0)
			throw new Exception("Duplicate rule name definition");

		_rules.push(rule);
		ArraySort.sort(_rules, (l, r) -> l.priority - r.priority);
	}

	/**
		Removes a next turn rule.
		@param name The name of the rule to be removed.
	**/
	final function removeRule(name:String)
		_rules = _rules.filter(i -> i.name != name);

	/**
		Toggles a rule's enabled state.
		@param The name of the rule to be toggled.
		@param enable _Optional._ Whether the rule should be enabled. If not defined, it will invert the rule's current state.
	**/
	final function toggleRule(name:String, ?enable:Bool)
	{
		var rule = _rules.filter(i -> i.name == name);
		if (rule.length > 0)
			rule[0].disabled = switch (enable)
			{
				case null:
					rule[0].disabled != true;
				case x:
					!x;
			}
	}

	/**
		Evaluates the next turn loop.
		@return The result of evaluating the loop.
	**/
	public function nextTurn()
		return Next(generateBumper());

	/**
		Evaluates the next turn loop.
		@return The result of evaluating the loop.
	**/
	public final function runNextTurn()
	{
		if (_rules == null || _rules.length == 0)
			throw new Exception("No rules defined");

		for (rule in _rules)
		{
			if (rule.disabled)
				continue;

			switch (rule.condition)
			{
				case Always:
				// don't do anything; always execute
				case If(f):
					if (!f())
						continue;
			}

			switch (rule.execute)
			{
				case Execute(f):
					f();
				case Process(f):
					return f();
				case Return(r):
					return r;
				case Throw(s):
					throw new Exception(s);
			}
		}

		throw new Exception("Next turn request fell through");
	}

	/**
		Generates a new Next bumper.
		@param force By default, a new bumper will only be generated if there is no Next bumper. Set this to `true` to force generation regardless.
		@return The new bumper.
		@throws Exception An error is thrown if generation is attempted without a bumper generator being created first.
	**/
	public function generateBumper(force = false)
	{
		if (next == null || force)
		{
			if (_bg == null)
				throw new Exception("Attempted to generate bumper without generator");
			next = modifyBumper(_bg.weightedGenerate());
		}
		return next;
	}

	/**
		Modifies a bumper. Does nothing on its own; needs to be overridden.
		@param b The bumper to modify.
		@return The modified bumper. If not overridden, `b` is returned as-is.
	**/
	public function modifyBumper(b:Bumper)
		return b;

	/** Resets the player state. **/
	public function reset()
	{
		score = 0;
		block = 0;
		next = null;
		multiStack = _dfltMultiStack.slice(0);

		_bg.reset();
		if (_bgColorShuffle)
			_bg.shuffleColors();
	}

	/**
		Sets a registry value.
		@param key The value to be set.
		@param val The value to store.
		@return The given value.
	**/
	inline public function setreg(key, val)
		return _reg.set(key, val);

	/**
		Gets a registry value.
		@param key The value to retrieve.
		@return The requested value.
	**/
	inline public function getreg(key)
		return _reg.get(key);

	/** Saves the player state to text via Haxe's `Serializer`. **/
	@:keep
	private function hxSerialize(s:Serializer)
	{
		s.serialize(id);
		s.serialize(board.serialize());
		s.serialize(score);
		s.serialize(block);
		s.serialize(launched);
		s.serialize(next == null);
		if (next != null)
			s.serialize(next.serialize());
		s.serialize(multiStack);
		s.serialize(_dfltMultiStack);
		s.serialize(_bg);
		s.serialize(_bgColorShuffle);
		s.serialize(_reg);
	}

	// TODO: make boards hxSerializable

	/** _Abstract._ Loads the board data. **/
	abstract function deserializeBoard(data:DynamicAccess<Dynamic>):CommonBoard;

	/** Restores the player state from text via Haxe's `Unserializer`. **/
	@:keep
	private function hxUnserialize(u:Unserializer)
	{
		init();
		this.id = u.unserialize();
		this.board = deserializeBoard(u.unserialize());
		attachBoard();
		this.score = u.unserialize();
		this.block = u.unserialize();
		this.launched = u.unserialize();
		if (cast(u.unserialize(), Bool))
			this.next = Bumper.fromSaved(u.unserialize());
		this.multiStack = u.unserialize();
		_dfltMultiStack = u.unserialize();
		_bg = u.unserialize();
		_bgColorShuffle = u.unserialize();
		_reg = u.unserialize();
	}
}
