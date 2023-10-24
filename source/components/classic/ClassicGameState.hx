package components.classic;

import haxe.DynamicAccess;
import haxe.Json;
import haxe.Timer;
import boardObject.Bumper;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import components.archipelago.TurnerSubstate;
import components.classic.ClassicHUD;
import components.common.CommonBoard;
import components.common.CommonGameState;
import components.common.CommonPlayerState;

class ClassicGameState extends CommonGameState
{
	/** A shortcut to cast `_hud` as `ClassicHUD`. **/
	private var _hudClassic(get, never):ClassicHUD;

	/** A shortcut to cast `_board` as `ClassicBoard`. **/
	private var _boardClassic(get, never):ClassicBoard;

	/** A shortcut to cast `_p` as `ClassicPlayerState`. **/
	private var _pClassic(get, never):ClassicPlayerState;

	/** A GUI element to display which color was selected for Paint Can use. **/
	private var _paintCanBumper:Bumper = null;

	/** A button to cancel Paint Can use. **/
	private var _paintCanCancelButton:FlxButton = null;

	/** The current selected color during a Paint Can event. **/
	private var _selectedColor:Null<FlxColor> = null;

	// !------------------------- INSTANTIATION

	override function create()
	{
		super.create();

		attachPlayer(_p);
		_hud.attachState(_p);
		prepareBoard();

		_p.runNextTurn();
	}

	function utilBtn()
	{
		#if kiosktest
		clearGame();
		FlxG.switchState(new ClassicGameState());
		#else
		_pClassic.paint++;
		#end
	}

	// !------------------------- PROPERTY HANDLERS

	function get_gameName()
		return "classic";

	function get_gameType()
		return "classic";

	inline function get__hudClassic()
		return cast(_hud, ClassicHUD);

	inline function get__boardClassic()
		return cast(_p.board, ClassicBoard);

	inline function get__pClassic()
		return cast(_p, ClassicPlayerState);

	// !------------------------- EVENT HANDLERS

	/**
		Called when the state of a connected player's board has changed.
		@param id The seconding player's identity string.
		@param state The current board state's identifier.
	**/
	function onBoardStateChanged(id:String, state:String)
	{
		// TODO: should this go into CommonGameState? also can this be modular like runNextTurn?
		var index = _playersv2.map(i -> i.id).indexOf(id);
		if (index >= 0)
			switch (state)
			{
				case "initial":
					switch (_playersv2[index].runNextTurn())
					{
						case Next(_):
							saveGame();
						case Notice(s):
							s.closeCallback = () -> onBoardStateChanged(id, state);
							openSubState(s);
						case Wait(msec):
							Timer.delay(() -> onBoardStateChanged(id, state), msec);
						default:
					}
				case "gameoverwait":
					FlxG.sound.play(AssetPaths.gameover__wav);
					if (gameType == "classic")
						clearGame();
				default:
			}
	}

	/**
		Called when a `Signal` is received from the player state.
		@param signal The signal string.
	**/
	function onSignal(signal:String) {}

	// TODO: make Paint Cans work more like Turners
	// in other words: click the button, pick a bumper, colour wheel shows up around it, pick a colour

	/** Called when the Paint Can button is clicked. **/
	function onPaintCanClick()
	{
		if (_pClassic.paint > 0 && _boardClassic.state == "initial" && _selectedColor == null)
		{
			FlxG.sound.play(AssetPaths.mselect__wav);
			var paintDialog = _pClassic.makePaintCanSubstate();
			paintDialog.onDialogResult.add(onColorSelect);
			openSubState(paintDialog);
		}
	}

	/** Called when a color is selected, or the color dialog is cancelled. **/
	function onColorSelect(?color:FlxColor)
	{
		if (_selectedColor != null)
			return;

		if (color != null)
		{
			var b = _boardClassic;

			FlxG.sound.play(AssetPaths.mselect__wav);
			_selectedColor = color;
			b.selectMode();

			if (_paintCanBumper == null)
			{
				_paintCanBumper = new Bumper(b.center.x - ((b.bWidth + 2) * b.sWidth / 2), b.center.y + (b.bHeight * b.sHeight / 2), _selectedColor, Clearing);
				_paintCanBumper.scale.set(.75, .75);
				_paintCanBumper.isUIElement = true;
				add(_paintCanBumper);
			}
			else
			{
				_paintCanBumper.bColor = _selectedColor;
				_paintCanBumper.revive();
			}
			if (_paintCanCancelButton == null)
			{
				_paintCanCancelButton = new FlxButton(b.center.x + (b.bWidth * b.sWidth / 2) + 20, b.center.y + (b.bHeight * b.sHeight / 2) + 20, "X",
					onFieldCancel);
				_paintCanCancelButton.loadGraphic(AssetPaths.button__png, true, 20, 20);
				_paintCanCancelButton.scale.set(2, 2);
				_paintCanCancelButton.scrollFactor.set(1, 1);
				add(_paintCanCancelButton);
			}
			else
				_paintCanCancelButton.revive();
		}
		else
			FlxG.sound.play(AssetPaths.mback__wav);
	}

	/** Called when the Cancel button is clicked during a Paint Can event. **/
	function onFieldCancel()
		if (_selectedColor != null)
			onBumperSelect(_p.id, null);

	/**
		Called when the Next bumper is clicked.
		@param bumper The clone of the Next bumper from the HUD.
	**/
	function onNextBumperClick(bumper:Bumper)
	{
		if (_selectedColor != null)
		{
			var nextClone = _p.next.cloneBumper();
			onBumperSelect(_p.id, nextClone);
			_p.next = nextClone;
		}
	}

	/**
		Called when a bumper is selected, or the bumper selection is cancelled.
		@param id The sending player's identity string.
		@param bumper The selected bumper.
	**/
	function onBumperSelect(id:String, bumper:Bumper)
	{
		if (id != _p.id)
			return;

		if (_selectedColor != null)
		{
			if (bumper != null)
			{
				// don't paint the bumper if it's colorless or the same color
				if (bumper.bColor == null || bumper.bColor == _selectedColor)
					return;
				FlxG.sound.play(AssetPaths.mselect__wav);
				_pClassic.paint--;
				bumper.bColor = _selectedColor;
			}
			else
				FlxG.sound.play(AssetPaths.mback__wav);
			_paintCanBumper.kill();
			_paintCanCancelButton.kill();
			_boardClassic.endPaint(_selectedColor == null);
			_selectedColor = null;
		}
	}

	// !------------------------- OVERRIDES & ABSTRACT DEFS

	/** Starts a new game. **/
	function createGame()
	{
		if (_playersv2.length == 0)
		{
			var p = new ClassicPlayerState("solo");
			p.createGenerator();
			p.createBoard();
			_playersv2.push(p);
		}

		if (_hud == null)
			_hud = new ClassicHUD();
	}

	/** Connects this game state to the HUD's events. **/
	function attachHUD()
	{
		_hud.onNextBumperClick.add(onNextBumperClick);
		_hudClassic.onPaintCanClick.add(onPaintCanClick);
	}

	/**
		Connects this game state to a player state's events.
		@param state The state to connect to the game state.
	**/
	override function attachPlayer(player:CommonPlayerState)
	{
		super.attachPlayer(player);
		var playerCl = cast(player, ClassicPlayerState);
		playerCl.onBumperSelected.add(onBumperSelect);
	}

	/**
		Disconnects this game state from a player state's events.
		@param state The state to disconnect from the game state.
	**/
	override function detachPlayer(player:CommonPlayerState)
	{
		super.detachPlayer(player);
		var playerCl = cast(player, ClassicPlayerState);
		playerCl.onBumperSelected.remove(onBumperSelect);
	}
}
