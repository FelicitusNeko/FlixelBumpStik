package components.common;

import components.common.CommonBoard;
import flixel.FlxG;
import haxe.Exception;
import flixel.FlxSubState;
import haxe.DynamicAccess;
import haxe.Serializer;
import haxe.Unserializer;
import boardObject.Bumper;
import boardObject.Launcher;
import flixel.util.FlxColor;
import lime.app.Event;

/** The result of calling for next turn. **/
enum TurnResult
{
	/** A bumper has been generated. **/
	Next(b:Bumper);

	/** A substate is to be displayed. **/
	Notice(s:FlxSubState);

	/** The game is over. **/
	Kill;

	/** A custom function is to be called. **/
	Custom(f:Void->Void);
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
		@return The new current score.
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
		return score += newAdd;
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

	function onInnerBoardStateChanged(state)
		onBoardStateChanged.dispatch(id, state);

	function onMatch(chain:Int, combo:Int, _)
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

	function onClear(chain:Int, _)
	{
		FlxG.sound.play(AssetPaths.clear__wav);
		block++;
		addScore(10 * Math.floor(Math.pow(2, chain - 1)));
	}

	// NOTE: maybe rework how this works
	function onLaunchSelect(cb:BumperCallback)
	{
		FlxG.sound.play(AssetPaths.launch__wav);

		var b = next == null ? _bg.weightedGenerate() : next;
		next = null;
		addScore(5);
		cb(b);
	}

	/**
		Evaluates the next turn loop.
		@return The result of evaluating the loop.
	**/
	public function nextTurn()
		return Next(generateBumper());

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
		_bg = u.unserialize();
		_bgColorShuffle = u.unserialize();
		_reg = u.unserialize();
	}
}
