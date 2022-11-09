package;

import boardObject.Bumper;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import haxe.DynamicAccess;

/** Generates bumpers for play use. **/
class BumperGenerator
{
	/** The default array to convert numbers into colors. **/
	public static final defaultColorOpts:Array<FlxColor> = [Color.Blue, Color.Green, Color.Red, Color.Purple, Color.Yellow, Color.White];

	/** An array to convert numbers into colors. **/
	public var colorOpts:Array<FlxColor> = [];

	/** An array to convert numbers into directions. **/
	public static final dirOpts:Array<Direction> = [Up, Right, Down, Left];

	/** The number of colors this generator was initialized with. **/
	public var initColors(default, null):Int;

	/** The number of colors currently in play. **/
	public var colors(default, set):Int = 0;

	/** The maximum number of colors available to be put into play. **/
	public var maxColors(get, never):Int;

	/** The maximum number of colors to be made available, regardless of how many are actually on the list. **/
	public var colorLimit(default, set):Int;

	/** The average number of each color generated. **/
	public var average(get, never):Float;

	/** The most of any one color generated. **/
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

	function set_colors(colors:Int):Int
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

	function set_colorLimit(colorLimit:Int)
	{
		if (colorLimit < colors)
			colorLimit = colors;
		if (colorLimit > maxColors)
			colorLimit = maxColors;
		return this.colorLimit = colorLimit;
	}

	inline function get_maxColors()
		return colorOpts.length;

	function get_average():Float
	{
		if (colors == 0)
			return 0;
		var total = 0;
		for (_ => qty in _drops)
			total += qty;
		return total / colors;
	}

	function get_max():Int
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
	}

	public function serialize()
	{
		var retval:DynamicAccess<Dynamic> = {};

		retval["initColors"] = initColors;
		retval["colors"] = colors;
		retval["colorLimit"] = colorLimit;
		retval["colorOpts"] = colorOpts;

		var dropsDA:DynamicAccess<Int> = {};
		for (col => drop in _drops)
			dropsDA[Std.string(col)] = drop;

		retval["drops"] = dropsDA;

		// TODO: maybe save the state of the RNG

		return retval;
	}

	public function deseralize(data:DynamicAccess<Dynamic>){
		colorLimit = data["colorLimit"];
		colors = data["colors"];

		var dropsDA:DynamicAccess<Int> = data["drops"];
		for (col => drop in dropsDA)
			_drops[Std.parseInt(col)] = drop;
	}

	public static function fromSaved(data:DynamicAccess<Dynamic>) {
		var retval = new BumperGenerator(data["initColors"], data["colorOpts"]);
		retval.deseralize(data);
		return retval;
	}
}
