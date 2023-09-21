package;

import haxe.DynamicAccess;
import haxe.Serializer;
import haxe.Unserializer;
import boardObject.Bumper;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;

/** Generates bumpers for play use. **/
class BumperGenerator
{
	/** The default array to convert numbers into colors. **/
	public static final defaultColorOpts:Array<FlxColor> = [Color.Blue, Color.Green, Color.Red, Color.Purple, Color.Yellow, Color.White];

	/** An array to convert numbers into directions. **/
	public static final dirOpts:Array<Direction> = [Up, Right, Down, Left];

	/** An array to convert numbers into colors. **/
	public var colorOpts:Array<FlxColor> = [];

	/** The number of colors this generator was initialized with. **/
	public var initColors(default, null):Int;

	/** The number of colors currently in play. **/
	public var colors(default, set):Int = 0;

	/** The maximum number of colors to be made available, regardless of how many are actually on the list. **/
	public var colorLimit(default, set):Int;

	/** _Read-only._ An array of the colors currently in play. **/
	public var colorsInPlay(get, never):Array<FlxColor>;

	/** _Read-only._ The maximum number of colors available to be put into play. **/
	public var maxColors(get, never):Int;

	/** _Read-only._ The average number of each color generated. **/
	public var average(get, never):Float;

	/** _Read-only._ The most of any one color generated. **/
	public var max(get, never):Int;

	/** The random generator for this class. **/
	private var _rng = new FlxRandom();

	/** The quantity of each color that has been generated **/
	private var _drops:Map<FlxColor, Int> = [];

	public function new(initColors:Int, ?initOpts:Array<FlxColor>)
	{
		colorOpts = initOpts != null ? initOpts.copy() : defaultColorOpts.copy();
		colorLimit = maxColors;
		colors = this.initColors = initColors;
	}

	private function set_colors(colors:Int):Int
	{
		if (colors < 0)
			colors = 0;
		else if (colors > colorLimit)
			colors = colorOpts.length;

		if (colors == 0)
		{
			this.colors = 0;
			_drops.clear();
		}
		else if (colors != this.colors)
		{
			var avg = Math.round(average);
			while (this.colors < colors)
				_drops.set(colorOpts[this.colors++], avg);
			while (this.colors > colors)
				_drops.remove(colorOpts[--this.colors]);
		}
		return this.colors;
	}

	private function set_colorLimit(colorLimit:Int)
	{
		if (colorLimit < colors)
			colorLimit = colors;
		if (colorLimit > maxColors)
			colorLimit = maxColors;
		return this.colorLimit = colorLimit;
	}

	private inline function get_colorsInPlay()
		return colorOpts.slice(0, colors);

	private inline function get_maxColors()
		return colorOpts.length;

	private function get_average():Float
	{
		if (colors == 0)
			return 0;
		var total = 0;
		for (_ => qty in _drops)
			total += qty;
		return total / colors;
	}

	private function get_max():Int
	{
		var retval = 0;
		for (_ => qty in _drops)
			retval = Math.round(Math.max(qty, retval));
		return retval;
	}

	/** Shuffles the list of colors to use. This will also reset generation statistics. **/
	public function shuffleColors()
	{
		var _colors = colors;
		colors = 0;
		_rng.shuffle(colorOpts);
		colors = _colors;
	}

	/**
		Generates a new bumper.
		@param color Optional. Forces the bumper to be a specific color.
		@param direction Optional. Forces the bumper to be facing a specific direction.
		@return The generated bumper.
	**/
	public function generate(?color:FlxColor, ?direction:Direction)
	{
		if (color == null)
			color = _rng.getObject(colorOpts, null, 0, colors - 1);
		if (direction == null)
			direction = _rng.getObject(dirOpts);

		_drops[color]++;

		return new Bumper(0, 0, color, direction);
	}

	/** 
		Generates a new bumper, trying to keep each color balanced.
		@return The generated bumper.
	**/
	public function weightedGenerate()
	{
		var maxplus1 = max + 1;
		var weights:Array<Float> = [];

		for (i in 0...colors)
			weights.push(maxplus1 - _drops[colorOpts[i]]);

		var color = _rng.getObject(colorOpts, weights, 0, colors - 1);
		return generate(color);
	}

	/**
		Generates a random color from the available list.
		@param track Optional. Whether to track 
		@return The generated color.
	**/
	public function generateColor(track = false)
	{
		var retval = _rng.getObject(colorOpts, null, 0, colors - 1);
		if (track)
			_drops[retval]++;
		return retval;
	}

	/** Resets the generator to its initial setting. **/
	public function reset()
	{
		colors = 0;
		colors = initColors;
		colorLimit = maxColors;
		_rng = new FlxRandom();
	}

	@:keep
	private function hxSerialize(s:Serializer)
	{
		s.serialize(colorOpts);
		s.serialize(initColors);
		s.serialize(colors);
		s.serialize(colorLimit);
		s.serialize(_drops);
		s.serialize(_rng.initialSeed);
		s.serialize(_rng.currentSeed);
	}

	@:keep
	private function hxUnserialize(u:Unserializer)
	{
		colorOpts = u.unserialize();
		initColors = u.unserialize();
		colors = u.unserialize();
		colorLimit = u.unserialize();
		_drops = u.unserialize();
		_rng = new FlxRandom(u.unserialize());
		_rng.currentSeed = u.unserialize();
	}
}
