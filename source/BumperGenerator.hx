package;

import boardObject.Bumper;
import flixel.math.FlxRandom;

/** Generates bumpers for play use. **/
class BumperGenerator
{
	/** An array to convert numbers into colors. **/
	public static final colorOpts:Array<Color> = [Blue, Green, Red, Purple, Yellow, White];

	/** An array to convert numbers into directions. **/
	public static final dirOpts:Array<Direction> = [Up, Right, Down, Left];

	/** The number of colors this generator was initialized with. **/
	public var initColors(default, null):Int;

	/** The number of colors currently in play. **/
	public var colors(default, set):Int;

	/** The average number of each color generated. **/
	public var average(get, never):Float;

	/** The most of any one color generated. **/
	public var max(get, never):Int;

	/** The random generator for this class. **/
	private var _rng = new FlxRandom();

	/** The quantity of each color that has been generated **/
	private var _drops:Map<Color, Int> = [];

	public function new(initColors:Int)
	{
		this.initColors = initColors;
		colors = initColors;
	}

	function set_colors(colors:Int):Int
	{
		var avg = Math.round(average);
		if (colors == 0)
			_drops.clear();
		else
		{
			while (this.colors < colors)
				_drops.set(colorOpts[this.colors++], avg);
			while (this.colors > colors)
				_drops.remove(colorOpts[--this.colors]);
		}
		return this.colors;
	}

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

	/**
		Generates a new bumper.
		@param color Optional. Forces the bumper to be a specific color.
		@param direction Optional. Forces the bumper to be facing a specific direction.
		@return The generated bumper.
	**/
	public function generate(?color:Color, ?direction:Direction)
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

		for (_ => qty in _drops)
			weights.push(maxplus1 - qty);

		var color = _rng.getObject(colorOpts, weights, 0, colors - 1);
		return generate(color);
	}

	/** Resets the generator to its initial setting. **/
	public function reset()
	{
		colors = 0;
		colors = initColors;
	}
}
