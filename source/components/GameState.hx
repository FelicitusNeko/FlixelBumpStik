package components;

import Main.I18nFunction;
import components.StandardHUD;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import haxe.DynamicAccess;
import haxe.Exception;
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
	private var _bg:BumperGenerator;

	/** Pulls a string from the i18n bank. **/
	private var _t:I18nFunction;

	/** Read-only. The internal name for this game. **/
	public var gameName(get, never):String;

	/** Read-only. The type of game. **/
	public var gameType(get, never):String;

	public function new()
	{
		if (_bg == null)
			_bg = new BumperGenerator(3);
		_t = BumpStikGame.g().i18n.tr;
		super();
	}

	function get_gameName()
		return "default";

	function get_gameType()
		return "generic";

	function get__player()
		return _players.length == 0 ? null : _players[0];

	override function create()
	{
		var save = new FlxSave();
		save.bind(gameName);
		trace(save.data);
		if (save.data.gameName == gameName)
		{
			trace('save data $gameName found');
			deserialize(save.data);
		}
		else
			createGame();
		save.close();

		var mainCamera = FlxG.camera;
		var hudCamera:FlxCamera;

		mainCamera.antialiasing = true;

		if (FlxG.width > FlxG.height)
			hudCamera = new FlxCamera(Math.round(FlxG.width * .75), 0, Math.round(FlxG.width / 4), FlxG.height);
		else
			hudCamera = new FlxCamera(0, Math.round(FlxG.height * .8), FlxG.width, Math.round(FlxG.height / 5));

		FlxG.cameras.add(hudCamera, false);
		_hud.cameras = [hudCamera];
		hudCamera.update(0);
		hudCamera.bgColor = FlxColor.TRANSPARENT;
		hudCamera.zoom = hudCamera.width / _hud.width;
		hudCamera.antialiasing = true;
		hudCamera.focusOn(new FlxPoint(_hud.width / 2, _hud.height / 2));

		super.create();
	}

	function createGame()
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
	}

	function serialize():DynamicAccess<Dynamic>
	{
		var retval:DynamicAccess<Dynamic> = {};

		retval["gameName"] = gameName;
		retval["players"] = _players.map(p ->
		{
			var iretval:DynamicAccess<Dynamic> = {};

			iretval["multStack"] = p.multStack;
			iretval["board"] = p.board.serialize();

			return iretval;
		});

		retval["hud"] = _hud.serialize();
		retval["bg"] = _bg.serialize();

		return retval;
	}

	function deserialize(data:DynamicAccess<Dynamic>, ignoreGameName = false)
	{
		if (data["gameName"] != gameName && !ignoreGameName)
			throw new Exception("Game name mismatch");

		// for (player in _players)
		// 	if (player.board != null)
		// 		player.board.destroy();
		// while (_players.pop() != null) {}

		// for (player in data["players"])
		// {
		// 	var newBoard = new Board

		// 	player["multStack"]
		// }
	}

	function prepareBoard()
	{
		var mainCamera = FlxG.camera;
		var hudCamera = FlxG.cameras.list[1];

		add(_player.board);

		if (FlxG.width > FlxG.height)
		{
			mainCamera.zoom = Math.min((FlxG.width - hudCamera.width) / _player.board.tWidth, FlxG.height / _player.board.tHeight) * (14 / 15);
			mainCamera.focusOn(_player.board.center.add(hudCamera.width / 2 / FlxG.camera.zoom, 0));
		}
		else
		{
			mainCamera.zoom = Math.min(FlxG.width / _player.board.tWidth, (FlxG.height - hudCamera.height) / _player.board.tHeight) * (14 / 15);
			mainCamera.focusOn(_player.board.center.add(hudCamera.width / 2 / FlxG.camera.zoom, 0));
		}
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

	override function update(elapsed:Float)
	{
		#if (debug && sys && !noescape)
		if (FlxG.keys.anyJustPressed([ESCAPE]))
			System.exit(0);
		#end

		super.update(elapsed);
	}
}
