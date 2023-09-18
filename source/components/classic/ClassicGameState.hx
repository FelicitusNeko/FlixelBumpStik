package components.classic;

import haxe.DynamicAccess;
import haxe.Json;
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
	/**
		The value of the All Clear jackpot.
		@deprecated moving to `ClassicPlayerState`
	**/
	private var _jackpot:Int = 0;

	/** A GUI element to display which color was selected for Paint Can use. **/
	private var _paintCanBumper:Bumper = null;

	/** A button to cancel Paint Can use. **/
	private var _paintCanCancelButton:FlxButton = null;

	/**
		The number of bumpers to clear to add a new color.
		@deprecated moving to `ClassicPlayerState`
	**/
	private var _nextColor:Int = 100;

	/**
		The number of bumpers to clear to add a new color.
		@deprecated moving to `ClassicPlayerState`
	**/
	private var _nextColorEvery:Int = 150;

	/** A shortcut to cast `_hud` as `ClassicHUD`. **/
	private var _hudClassic(get, never):ClassicHUD;

	/** A shortcut to cast `_board` as `ClassicBoard`. **/
	private var _boardClassic(get, never):ClassicBoard;

	/** The current selected color during a Paint Can event. **/
	private var _selectedColor:Null<FlxColor> = null;

	function get_gameName()
		return "classic";

	function get_gameType()
		return "classic";

	inline function get__hudClassic()
		return cast(_hud, ClassicHUD);

	inline function get__boardClassic()
		return cast(_p.board, ClassicBoard);

	override function create()
	{
		super.create();

		_hud.attachState(_p);
		prepareBoard();

		if (gameType == "classic")
		{
			#if kiosktest
			var restart = new FlxButton(0, 0, "Restart", () ->
			{
				clearGame();
				FlxG.switchState(new ClassicGameState());
			});
			_hud.add(restart);
			#elseif debug
			var test = new FlxButton(0, 0, "Test", () ->
			{
				trace("Test is currently GNDN");
			});
			_hud.add(test);
			#end
		}

		onBoardStateChanged(_p.id, "initial");
	}

	function createGame()
	{
		trace("ClGS.createGame");
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

	override function attachPlayer(player:CommonPlayerState)
	{
		super.attachPlayer(player);
		var playerCl = cast(player, ClassicPlayerState);
		playerCl.onBumperSelected.add(onBumperSelect);
	}

	override function detachPlayer(player:CommonPlayerState)
	{
		super.detachPlayer(player);
		var playerCl = cast(player, ClassicPlayerState);
		playerCl.onBumperSelected.remove(onBumperSelect);
	}

	function onBoardStateChanged(id:String, state:String)
	{
		var index = _playersv2.map(i -> i.id).indexOf(id);
		if (index >= 0)
			switch (state)
			{
				case "initial":
					switch (_playersv2[index].nextTurn())
					{
						case Next(_):
							saveGame();
						case Notice(s):
							s.closeCallback = () -> onBoardStateChanged(id, state);
							openSubState(s);
						default:
					}
				case "gameoverwait":
					FlxG.sound.play(AssetPaths.gameover__wav);
					if (gameType == "classic")
						clearGame();
				default:
			}
	}

	// TODO: make Paint Cans work more like Turners
	// in other words: click the button, pick a bumper, colour wheel shows up around it, pick a colour

	/** Called when the Paint Can button is clicked. **/
	function onPaintCanClick()
	{
		if (_boardClassic.state == "initial" && _selectedColor == null)
		{
			FlxG.sound.play(AssetPaths.mselect__wav);
			var bumperSize = new FlxPoint(_hud.nextBumper.width, _hud.nextBumper.height).scale(.5);
			var paintDialog = new PaintCanSubstate(_boardClassic.center.subtractPoint(bumperSize), _bg.colors, _bg);
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

	function onFieldCancel()
		if (_selectedColor != null)
			onBumperSelect(_p.id, null);

	/** Called when a bumper is selected, or the bumper selection is cancelled. **/
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
				_hudClassic.paintCans--;
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
}
