package components.common;

import haxe.Serializer;
import haxe.Unserializer;
import boardObject.Bumper;
import boardObject.Launcher;
import flixel.util.FlxColor;
import lime.app.Event;

class PlayerState
{
	public var onScoreChanged(default, null) = new Event<Int->Void>();
	public var onBlockChanged(default, null) = new Event<Int->Void>();
	public var onLaunch(default, null) = new Event<Bumper->Void>();
	public var onNextChanged(default, null) = new Event<Bumper->Void>();

	public var score(default, set) = 0;
	public var block(default, set) = 0;
	public var next(default, set):Bumper = null;
	public var multiStack(get, default) = [1.0];

	private var _bg:BumperGenerator;
	private var _bgColorShuffle = false;

	public function new() {}

	private function set_score(score)
	{
		onScoreChanged.dispatch(this.score = score);
		return this.score;
	}

	private function set_block(block)
	{
		onBlockChanged.dispatch(this.block = block);
		return this.block;
	}

	private function set_next(next)
	{
		onNextChanged.dispatch(this.next = next);
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
		onLaunch.dispatch(next);
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
		@return The new current score.
	**/
	public function addScore(add:Int)
	{
		var addF:Float = add;
		for (x in multiStack)
			addF *= x;
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

	@:keep
	private function hxSerialize(s:Serializer)
	{
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
		this.score = u.unserialize();
		this.block = u.unserialize();
		if (cast(u.unserialize(), Bool))
			this.next = Bumper.fromSaved(u.unserialize());
		this.multiStack = u.unserialize();
		_bg = u.unserialize();
		_bgColorShuffle = u.unserialize();
	}
}
