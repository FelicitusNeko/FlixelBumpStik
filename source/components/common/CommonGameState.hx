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
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import openfl.system.System;
import state.MenuState;
import components.common.CommonHUD;
import components.dialogs.DialogBox;

abstract class CommonGameState extends FlxState
{
	private static var _utilButton:Null<String> =
		#if kiosktest
		"Restart"
		#elseif debug
		"Test"
		#else
		null
		#end;

	/** The list of players for this game. **/
	private var _playersv2:Array<CommonPlayerState> = [];

	/** The GUI for this game. **/
	private var _hud:CommonHUD;

	/** A shortcut to the local player. **/
	private var _p(get, never):CommonPlayerState;

	/** Pulls a string from the i18n bank. **/
	private var _t:I18nFunction;

	/** If this is set, the game will transition to a different scene on the next call to `update`. **/
	private var _queueTo:Null<FlxState> = null;

	/** Read-only. The internal name for this game. **/
	public var gameName(get, never):String;

	/** Read-only. The type of game. **/
	public var gameType(get, never):String;

	// !------------------------- INSTANTIATION

	public function new()
	{
		_t = BumpStikGame.g().i18n.tr;
		super();
	}

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

		var camMain = FlxG.camera;
		var camHUD:FlxCamera;

		camMain.antialiasing = true;

		if (_hud.rightSide)
			camHUD = new FlxCamera(Math.round(FlxG.width * .75), 0, Math.round(FlxG.width / 4), FlxG.height);
		else
			camHUD = new FlxCamera(0, Math.round(FlxG.height * .8), FlxG.width, Math.round(FlxG.height / 5));

		FlxG.cameras.add(camHUD, false);
		_hud.cameras = [camHUD];
		camHUD.update(0);
		camHUD.bgColor = FlxColor.TRANSPARENT;
		camHUD.zoom = camHUD.width / _hud.width;
		camHUD.antialiasing = true;
		camHUD.focusOn(new FlxPoint(_hud.width / 2, _hud.height / 2));

		if (_utilButton != null)
			_hud.add(new FlxButton(0, 0, "Test", utilBtn));

		super.create();
	}

	abstract function utilBtn():Void;

	// !------------------------- PROPERTY HANDLERS

	abstract function get_gameName():String;

	abstract function get_gameType():String;

	inline function get__p()
		return _playersv2.length == 0 ? null : _playersv2[0];

	// !------------------------- METHODS

	/** Starts a new game. **/
	abstract function createGame():Void;

	/** Connects this game state to the HUD's events. **/
	abstract function attachHUD():Void;

	/**
		Connects this game state to a player state's events.
		@param state The state to connect to the game state.
	**/
	function attachPlayer(player:CommonPlayerState)
	{
		player.onBoardStateChanged.add(onBoardStateChanged);
	}

	/**
		Disconnects this game state from a player state's events.
		@param state The state to disconnect from the game state.
	**/
	function detachPlayer(player:CommonPlayerState)
	{
		player.onBoardStateChanged.remove(onBoardStateChanged);
	}

	/**
		Saves the game in progress.
		@param file _Optional._ The file to erase. If not specified, `gameName` is used.
	**/
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

	/**
		Erases a save file.
		@param file _Optional._ The file to erase. If not specified, `gameName` is used.
	**/
	function clearGame(?file:String)
	{
		if (file == null)
			file = gameName;

		var save = new FlxSave();
		save.bind(file);
		save.erase();
	}

	/** Prepares the players' board(s) to be displayed and used by the game state. **/
	function prepareBoard()
	{
		for (player in _playersv2)
			add(player.board);

		if (_p.board != null)
		{
			var camMain = FlxG.camera;
			var camHUD = FlxG.cameras.list[1];

			if (_hud.rightSide)
			{
				camMain.zoom = Math.min((FlxG.width - camHUD.width) / _p.board.tWidth, FlxG.height / _p.board.tHeight) * (14 / 15);
				camMain.focusOn(_p.board.center.add(camHUD.width / 2 / FlxG.camera.zoom, 0));
			}
			else
			{
				camMain.zoom = Math.min(FlxG.width / _p.board.tWidth, (FlxG.height - camHUD.height) / _p.board.tHeight) * (14 / 15);
				camMain.focusOn(_p.board.center.add(camHUD.width / 2 / FlxG.camera.zoom, 0));
			}
		}
	}

	/**
		Shows an error dialog.
		@param text The caption for the error dialog.
		@param title _Optional._ The title for the error dialog. Defaults to `base/error` i18n string.
		@param fatal _Optional._ If `true`, closing the dialog will terminate the game in progress. Default `false`.
	**/
	final function showError(text:String, ?title:String, fatal = false)
	{
		var dlgDef:DialogOptions = {
			title: title == null ? _t("base/error") : title,
			titleColor: FlxColor.fromRGB(255, 127, 127)
		};
		if (fatal)
			dlgDef.defAccept = dlgDef.defCancel = Custom(() ->
			{
				_queueTo = new MenuState();
				return Close;
			});
		else
			dlgDef.defAccept = dlgDef.defCancel = Close;

		openSubState(new DialogBox(text, dlgDef));
	}

	/** Stringifies the game state's data to be saved to a file. **/
	function serialize():DynamicAccess<Dynamic>
	{
		var retval:DynamicAccess<Dynamic> = {};

		retval["version"] = BumpStikGame.curSaveVer;
		retval["gameName"] = gameName;
		retval["gameType"] = gameType;

		retval["players"] = Serializer.run(_playersv2);

		return retval;
	}

	/**
		Parses serialized data and loads it into the game state.
		@param data The data to be parsed.
		@param ignoreGameName _Optional._ If `true`, will load whether or not the `gameName` matches. Defaults to `false`, and should only be set to `true` by child overrides.
	**/
	function deserialize(data:DynamicAccess<Dynamic>, ignoreGameName = false)
	{
		if (data["gameName"] != gameName && !ignoreGameName)
			throw new Exception("Game name mismatch");

		_playersv2 = Unserializer.run(data["players"]);
	}

	// !------------------------- EVENT HANDLERS

	/**
		Called when the state of a connected player's board has changed.
		@param id The seconding player's identity string.
		@param state The current board state's identifier.
	**/
	abstract function onBoardStateChanged(id:String, state:String):Void;

	// !------------------------- OVERRIDES

	override function update(elapsed:Float)
	{
		#if (debug && sys && !noescape)
		if (FlxG.keys.anyJustPressed([ESCAPE]))
			System.exit(0);
		#end

		super.update(elapsed);

		if (_queueTo != null)
			FlxG.switchState(_queueTo);
	}
}
