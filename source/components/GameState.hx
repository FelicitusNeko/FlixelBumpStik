package components;

import boardObject.Bumper;
import components.StandardHUD;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.system.System;

/** Stats for each player. **/
typedef PlayerInstance =
{
	/** The board to be used for this player. **/
	var board:Board;

	/** The player's current score multiplier stack. **/
	var multStack:Array<Float>;
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
				board: new Board(0, 0),
				multStack: [1]
			});
		}

		for (player in _players)
			add(player.board);

		if (_hud == null)
			_hud = new StandardHUD();
		add(_hud);

		// _hud.nextBumper = _bg.weightedGenerate();

		var hudCamera:FlxCamera;
		var wWidth:Float = FlxG.width, wHeight:Float = FlxG.height;
		if (FlxG.width > FlxG.height)
		{
			wWidth *= .75;
			hudCamera = new FlxCamera(Math.round(wWidth), 0, Math.round(FlxG.width / 4), FlxG.height);
		}
		else
		{
			wHeight *= .8;
			hudCamera = new FlxCamera(0, Math.round(wHeight), FlxG.width, Math.round(FlxG.height / 5));
		}

		hudCamera.bgColor = FlxColor.TRANSPARENT;
		_hud.cameras = [hudCamera];
		FlxG.cameras.add(hudCamera, false);
		hudCamera.antialiasing = true;

		FlxG.camera.zoom = Math.min(wWidth / _player.board.tWidth, wHeight / _player.board.tHeight) * (14 / 15);
		FlxG.camera.antialiasing = true;
		// FlxTween.tween(FlxG.camera, {zoom: 5}, 5, {onComplete: (_) -> FlxTween.tween(FlxG.camera, {zoom: 1}, 5)});
		// FlxTween.tween(hudCamera, {zoom: 5}, 5, {onComplete: (_) -> FlxTween.tween(hudCamera, {zoom: 1}, 5)});

		trace("Going with a zoom of " + FlxG.camera.zoom);

		FlxG.camera.focusOn(_player.board.center.add(_hud.width * hudCamera.zoom / 2 / FlxG.camera.zoom, 0));

		super.create();
	}

	function addScore(addScore:Int, ?multStack:Array<Float>)
	{
		if (addScore == 0)
			return 0;
		if (multStack == null)
			return addScore;

		var mult:Float = 1;
		for (factor in multStack)
			mult *= factor;
		var retval = Math.floor(addScore * mult);
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
