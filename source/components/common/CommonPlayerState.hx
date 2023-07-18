package components.common;

import haxe.Serializer;
import haxe.Unserializer;
import boardObject.Bumper;
import boardObject.Launcher;
import flixel.util.FlxColor;
import lime.app.Event;

/** Base class to keep the state of a player. **/
abstract class CommonPlayerState
{
	public var onScoreChanged(default, null):Event<(Int, Int) -> Void>;
	public var onBlockChanged(default, null):Event<(Int, Int) -> Void>;
	public var onBonus(default, null):Event<(Int, Int) -> Void>;
	public var onLaunch(default, null):Event<(Int, Bumper) -> Void>;
	public var onNextChanged(default, null):Event<(Int, Bumper) -> Void>;

	public var id(default, null) = 0;
	public var score(default, set) = 0;
	public var block(default, set) = 0;
	public var next(default, set):Bumper = null;
	public var multiStack(get, default) = [1.0];

	private var _bg:BumperGenerator;
	private var _bgColorShuffle = false;

	public function new(id:Int)
	{
		init();
		this.id = id;
	}

	/** Initializes things like event handlers. **/
	private function init()
	{
		onScoreChanged = new Event<(Int, Int) -> Void>();
		onBlockChanged = new Event<(Int, Int) -> Void>();
		onBonus = new Event<(Int, Int) -> Void>();
		onLaunch = new Event<(Int, Bumper) -> Void>();
		onNextChanged = new Event<(Int, Bumper) -> Void>();
	}

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
		return multiStack.slice(0);

	/**
		Launches the current bumper in stock.
		@param l The Launcher to launch from.
	**/
	public function launch(l:Launcher)
	{
		l.launchBumper(next);
		onLaunch.dispatch(id, next);
		next = null;
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
		var addF:Float = add;
		for (x in multiStack)
			addF *= x;
		if (isBonus)
			onBonus.dispatch(id, Math.round(addF));
		return score += Math.round(addF);
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
		Generates a new Next bumper.
		@param force By default, a new bumper will only be generated if there is no Next bumper. Set this to `true` to force generation regardless.
		@return The new bumper.
		@throws Exception An error is thrown if generation is attempted without a bumper generator being created first.
	**/
	public function generateBumper(force = false)
	{
		if (_bg == null)
			throw "Attempted to generate bumper without generator";
		if (next == null || force)
			next = _bg.weightedGenerate();
		return next;
	}

	public function reset()
	{
		score = 0;
		block = 0;
		next = null;
		multiStack = [1.0];

		_bg.reset();
		if (_bgColorShuffle)
			_bg.shuffleColors();
	}

	@:keep
	private function hxSerialize(s:Serializer)
	{
		s.serialize(id);
		s.serialize(score);
		s.serialize(block);
		s.serialize(next == null);
		if (next != null)
			s.serialize(next.serialize());
		s.serialize(multiStack);
		s.serialize(_bg);
		s.serialize(_bgColorShuffle);
	}

	@:keep
	private function hxUnserialize(u:Unserializer)
	{
		init();
		this.id = u.unserialize();
		this.score = u.unserialize();
		this.block = u.unserialize();
		if (cast(u.unserialize(), Bool))
			this.next = Bumper.fromSaved(u.unserialize());
		this.multiStack = u.unserialize();
		_bg = u.unserialize();
		_bgColorShuffle = u.unserialize();
	}
}
