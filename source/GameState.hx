package;

import boardObject.Bumper;
import flixel.FlxG;
import flixel.FlxState;
import openfl.system.System;

/** Stats for each player. **/
typedef PlayerInstance =
{
	/** The player's current score. **/
	var score:Int;

	/** The player's current count of bumpers sticked (cleared). **/
	var block:Int;

	/** The board to be used for this player. **/
	var board:Board;

	/** The next bumper to be put into play. **/
	var nextBumper:Bumper;
}

abstract class GameState extends FlxState
{
	/** The list of players for this game. **/
	private var _players:Array<PlayerInstance> = [];

	/** The GUI for this game. **/
	private var _gui:StandardGUI;

	/** The number of seconds to wait before the next action should take place. **/
	private var _delay:Float = 0;

	override function create()
	{
		if (_players.length == 0)
		{
			_players.push({
				score: 0,
				block: 0,
				board: new Board(50, 50),
				nextBumper: new Bumper(550, 400, Color.Blue)
			});
		}

		for (player in _players)
		{
			add(player.board);
			add(player.nextBumper);
			FlxG.camera.focusOn(player.board.center);
		}

		if (_gui == null)
			_gui = new StandardGUI();

		add(_gui);

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
