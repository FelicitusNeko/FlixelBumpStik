package;

import boardObject.Bumper;
import flixel.math.FlxRandom;

/** Generates bumpers for play use. **/
class BumperGenerator
{
	/** An array to convert numbers into colors. **/
	static final colorOpts:Array<Color> = [Blue, Green, Red, Purple, Yellow, White];

	/** An array to convert numbers into directions. **/
	static final dirOpts:Array<Direction> = [Up, Right, Down, Left];

	/** The number of colors this generator was initialized with. **/
	public var initColors(default, null):Int;

	/** The number of colors currently in play. **/
	public var colors:Int;

	/** The random generator for this class. **/
	private var _rng = new FlxRandom();

	public function new(initColors:Int)
	{
		this.initColors = initColors;
		colors = initColors;
	}

	/**
			Generates a new bumper.
		@param color Optional. Forces the bumper to be a specific color.
		@param direction Optional. Forces the bumper to be facing a specific direction.
		@return The generated bumper.
	**/
	public function generate(?color:Color, ?direction:Direction)
	{
		return new Bumper(0, 0, color != null ? color : colorOpts[_rng.int(0, colors - 1)], direction != null ? direction : dirOpts[_rng.int(0, 3)]);
	}

	/** This function is currently a stub that calls `generate()`. **/
	public function weightedGenerate()
	{
		return generate();
	}

	/** Resets the generator to its initial setting. **/
	public function reset()
	{
		colors = initColors;
	}
}
