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
	private var _hud:StandardHUD;

	/** The number of seconds to wait before the next action should take place. **/
	private var _delay:Float = 0;

	override function create()
	{
		if (_players.length == 0)
		{
			_players.push({
				score: 0,
				block: 0,
				board: new Board(0, 0),
				nextBumper: new Bumper(550, 400, Color.Blue)
			});
		}

		for (player in _players)
		{
			add(player.board);
			add(player.nextBumper);
		}

		if (_hud == null)
			_hud = new StandardHUD();

		add(_hud);
		FlxG.camera.focusOn(_players[0].board.center.add(_hud.width / 2, 0));
		// TODO: figure out how to make the HUD not be affected by zoom
		// FlxG.camera.zoom = .9;

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
