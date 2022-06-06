import Bumper.Color;
import flixel.FlxG;
import flixel.FlxState;
import openfl.system.System;

abstract class GameState extends FlxState
{
	/** The player's current score. **/
	public var score(default, null):Int = 0;

	/** The player's current count of bumpers sticked (cleared). **/
	public var block(default, null):Int = 0;

	/** The board to be used for this game. **/
	private var _board:Board;

	/** The next bumper to be put into play. **/
	private var _nextBumper:Bumper = null;

	/** The number of seconds to wait before the next action should take place. **/
	private var _delay:Float = 0;

	override function create()
	{
		_board = new Board();
		add(_board);

		_nextBumper = new Bumper(550, 400, Color.Blue);
		add(_nextBumper);

		FlxG.camera.focusOn(_board.center);

		super.create();
	}

	override function update(elapsed:Float)
	{
		_delay -= elapsed;
		if (_delay < 0)
		{
			// TODO: do movement things based on the negative of _delay
			_delay = 0;
		}

		#if (debug && sys)
		if (FlxG.keys.anyJustPressed([ESCAPE]))
			System.exit(0);
		#end

		super.update(elapsed);
	}
}
