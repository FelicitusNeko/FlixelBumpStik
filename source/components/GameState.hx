package components;

import boardObject.Bumper;
import components.StandardHUD;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxColor;
import openfl.system.System;

/** Stats for each player. **/
typedef PlayerInstance =
{
	/** The player's current score. **/
	var score:Int;

	/** The player's current count of bumpers sticked (cleared). **/
	var block:Int;

	/** The player's current score multiplier stack. **/
	var multStack:Array<Float>;

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

	/** A shortcut to the first player on the list. **/
	private var _player(get, never):PlayerInstance;

	/** The bumper generator for this game. **/
	private var _bg = new BumperGenerator(3);

	override function create()
	{
		if (_players.length == 0)
		{
			_players.push({
				score: 0,
				block: 0,
				multStack: [1],
				board: new Board(0, 0),
				nextBumper: _bg.generate()
			});
		}

		for (player in _players)
			add(player.board);

		if (_hud == null)
			_hud = new StandardHUD();

		_hud.nextBumper = _player.nextBumper;
		add(_hud);

		var hudCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		hudCamera.bgColor = FlxColor.TRANSPARENT;
		_hud.cameras = [hudCamera];
		FlxG.cameras.add(hudCamera, false);
		FlxG.camera.zoom = .9;
		FlxG.camera.focusOn(_player.board.center.add(_hud.width * hudCamera.zoom / 2 / FlxG.camera.zoom, 0));

		super.create();
	}

	static function addScore(player:PlayerInstance, addScore:Int)
	{
		if (addScore == 0)
			return 0;

		var mult:Float = 1;
		for (factor in player.multStack)
			mult *= factor;
		var retval = Math.floor(addScore * mult);
		player.score += retval;
		return retval;
	}

	function get__player()
	{
		return _players.length == 0 ? null : _players[0];
	}

	override function update(elapsed:Float)
	{
		#if (debug && sys)
		if (FlxG.keys.anyJustPressed([ESCAPE]))
			System.exit(0);
		#end

		super.update(elapsed);
	}
}
