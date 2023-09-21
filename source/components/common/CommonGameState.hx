package components.common;

import haxe.DynamicAccess;
import haxe.Exception;
import haxe.Serializer;
import haxe.Unserializer;
import Main.I18nFunction;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import openfl.system.System;
import components.common.CommonHUD;

/** Stats for each player. **/
typedef PlayerInstance =
{
	/** The board to be used for this player. **/
	var board:CommonBoard;

	/** The player's current score multiplier stack. **/
	var multStack:Array<Float>;
}

abstract class CommonGameState extends FlxState
{
	/**
		The list of players for this game.
		@deprecated Converting to PlayerState
	**/
	private var _players:Array<PlayerInstance> = [];

	/** The list of players for this game. **/
	private var _playersv2:Array<CommonPlayerState> = [];

	/** The GUI for this game. **/
	private var _hud:CommonHUD;

	/**
		A shortcut to the first player on the list.
		@deprecated Use `_p` instead
	**/
	private var _player(get, never):PlayerInstance;

	/** A shortcut to the local player. **/
	private var _p(get, never):CommonPlayerState;

	/**
		The bumper generator for this game.
		@deprecated Use the generator stored in `PlayerState` instead
	**/
	private var _bg:BumperGenerator;

	/** Pulls a string from the i18n bank. **/
	private var _t:I18nFunction;

	/** Read-only. The internal name for this game. **/
	public var gameName(get, never):String;

	/** Read-only. The type of game. **/
	public var gameType(get, never):String;

	public function new()
	{
		_t = BumpStikGame.g().i18n.tr;
		super();
	}

	abstract function get_gameName():String;

	abstract function get_gameType():String;

	function get__player()
		return _players.length == 0 ? null : _players[0];

	inline function get__p()
		return _playersv2.length == 0 ? null : _playersv2[0];

	override function create()
	{
		var save = new FlxSave();
		save.bind(gameName);

		if (save.data.version != BumpStikGame.curSaveVer || // if the save is outdated
			BumpStikGame.curSaveVer < 0) // or if we're in unstable testing mode
		{
			// potentially upgrade save data
			// for now, just discard it
			createGame();
		}
		else if (save.data.gameName != gameName)
			createGame();
		else
		{
			trace('save data $gameName found');
			deserialize(save.data);
		}

		save.destroy(); // we're not outputting save data here, so just dispose the save object

		add(_hud);
		attachHUD();

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

	abstract function createGame():Void;

	function attachPlayer(player:CommonPlayerState)
	{
		player.onBoardStateChanged.add(onBoardStateChanged);
	}

	function detachPlayer(player:CommonPlayerState)
	{
		player.onBoardStateChanged.remove(onBoardStateChanged);
	}

	abstract function attachHUD():Void;

	abstract function onBoardStateChanged(id:String, state:String):Void;

	function saveGame(?file:String)
	{
		if (file == null)
			file = gameName;

		var save = new FlxSave();
		save.bind(file);
		save.erase();
		save.bind(file);

		var data = serialize();
		for (key in data.keys())
			Reflect.setField(save.data, key, data[key]);
		save.data.timestamp = Date.now().getTime();

		save.close();
	}

	function clearGame(?file:String)
	{
		if (file == null)
			file = gameName;

		var save = new FlxSave();
		save.bind(file);
		save.erase();
	}

	function prepareBoard()
	{
		for (player in _playersv2)
			add(player.board);

		var mainCamera = FlxG.camera;
		var hudCamera = FlxG.cameras.list[1];

		if (FlxG.width > FlxG.height)
		{
			mainCamera.zoom = Math.min((FlxG.width - hudCamera.width) / _p.board.tWidth, FlxG.height / _p.board.tHeight) * (14 / 15);
			mainCamera.focusOn(_p.board.center.add(hudCamera.width / 2 / FlxG.camera.zoom, 0));
		}
		else
		{
			mainCamera.zoom = Math.min(FlxG.width / _p.board.tWidth, (FlxG.height - hudCamera.height) / _p.board.tHeight) * (14 / 15);
			mainCamera.focusOn(_p.board.center.add(hudCamera.width / 2 / FlxG.camera.zoom, 0));
		}
	}

	override function update(elapsed:Float)
	{
		#if (debug && sys && !noescape)
		if (FlxG.keys.anyJustPressed([ESCAPE]))
			System.exit(0);
		#end

		super.update(elapsed);
	}

	function serialize():DynamicAccess<Dynamic>
	{
		var retval:DynamicAccess<Dynamic> = {};

		retval["version"] = BumpStikGame.curSaveVer;
		retval["gameName"] = gameName;
		retval["gameType"] = gameType;

		retval["players"] = Serializer.run(_playersv2);

		return retval;
	}

	function deserialize(data:DynamicAccess<Dynamic>, ignoreGameName = false)
	{
		if (data["gameName"] != gameName && !ignoreGameName)
			throw new Exception("Game name mismatch");

		_playersv2 = Unserializer.run(data["players"]);
	}
}
