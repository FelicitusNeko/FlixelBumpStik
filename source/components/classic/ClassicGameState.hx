package components.classic;

import haxe.DynamicAccess;
import haxe.Json;
import boardObject.Bumper;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import components.Board;
import components.archipelago.TurnerSubstate;
import components.classic.ClassicHUD;

class ClassicGameState extends GameState
{
	/** The value of the All Clear jackpot. **/
	private var _jackpot:Int = 0;

	/** A GUI element to display which color was selected for Paint Can use. **/
	private var _paintCanBumper:Bumper = null;

	/** A button to cancel Paint Can use. **/
	private var _paintCanCancelButton:FlxButton = null;

	/** The number of bumpers to clear to add a new color. **/
	private var _nextColor:Int = 100;

	/** The number of bumpers to clear to add a new color. **/
	private var _nextColorEvery:Int = 150;

	/** A shortcut to cast `_hud` as `ClassicHUD`. **/
	private var _hudClassic(get, never):ClassicHUD;

	/** A shortcut to cast `_board` as `ClassicBoard`. **/
	private var _boardClassic(get, never):ClassicBoard;

	/** The current selected color during a Paint Can event. **/
	private var _selectedColor:Null<FlxColor> = null;

	override function get_gameName()
		return "classic";

	override function get_gameType()
		return "classic";

	override function create()
	{
		super.create();

		var hud = _hudClassic;
		hud.onPaintCanGet.add((_) -> FlxG.sound.play(AssetPaths.paintcan__wav));
		hud.onPaintCanClick.add(onPaintCanClick);
		hud.onNextBumperClick.add(onBumperSelect);

		prepareBoard();

		#if kiosktest
		var restart = new FlxButton(0, 0, "Restart", () ->
		{
			clearGame();
			FlxG.switchState(new ClassicGameState());
		});
		_hud.add(restart);
		#else
		// var test = new FlxButton(0, 0, "Test", () ->
		// {
		// 	// openSubState(new AllClearSubstate(12345, _boardClassic.center));

		// 	// _hudClassic.paintCans++;

		// 	// trace(Json.stringify(serialize()));

		// 	// var load = new FlxSave();
		// 	// load.bind("testFile");
		// 	// if (load.data.gameName == null)
		// 	// {
		// 	// 	load.destroy();
		// 	// 	saveGame("testFile");
		// 	// }
		// 	// else
		// 	// {
		// 	// 	trace(Json.stringify(load.data));
		// 	// 	_boardClassic.bCount == 0 ? load.erase() : load.destroy();
		// 	// }

		// 	// var bumper = _boardClassic.getRandomBumper();
		// 	// if (bumper != null && bumper.alive)
		// 	// 	openSubState(new TurnerSubstate(bumper.getPosition(), bumper.direction, bumper.bColor));
		// });
		// _hud.add(test);
		#end
	}

	override function createGame()
	{
		if (_players.length == 0)
			_players.push({
				board: new ClassicBoard(0, 0),
				multStack: [1]
			});

		if (_hud == null)
			_hud = new ClassicHUD();

		if (_bg == null)
			_bg = new BumperGenerator(3);
	}

	override function prepareBoard()
	{
		super.prepareBoard();

		var board = _boardClassic;
		board.onRequestGenerate.add(onRequestGenerate);
		board.onMatch.add(onMatch);
		board.onClear.add(onClear);
		board.onLaunchBumper.add(onLaunch);
		board.onBumperSelect.add(onBumperSelect);
		board.onGameOver.add(onGameOver);
	}

	inline function get__hudClassic()
		return cast(_hud, ClassicHUD);

	inline function get__boardClassic()
		return cast(_player.board, ClassicBoard);

	/** Calculates score to be added. **/
	override function addScore(add:Int, ?multStack:Array<Float>):Int
	{
		_jackpot += add;
		return super.addScore(add, multStack);
	}

	/** Called when the board requests a bumper to be generated. Usually when it goes into Idle state. **/
	function onRequestGenerate()
	{
		if (_player.board.bCount <= 0 && _jackpot > 0)
		{
			FlxG.sound.play(AssetPaths.allclear__wav);
			var mJackpot = addScore(_jackpot, _player.multStack);
			_jackpot = 0;
			_hud.bonus = mJackpot;
			trace('All Clear - Awarding jackpot of $mJackpot');

			var allClearSub = new AllClearSubstate(mJackpot, _boardClassic.center);
			allClearSub.closeCallback = onRequestGenerate;
			openSubState(allClearSub);
		}
		else if (_hud.block >= _nextColor && _bg.colors < _bg.colorLimit)
		{
			FlxG.sound.play(AssetPaths.levelup__wav);
			var prevNextColor = _nextColor;
			_nextColor += _nextColorEvery;
			_player.multStack[0] += .2;
			trace('Threshold hit ${_hud.block}/$prevNextColor blk - adding new colour, now at ${_bg.colors}/${_bg.colorLimit}, next at $_nextColor');

			var newColorSub = new NewColorSubstate(_bg.colorOpts[_bg.colors++], _boardClassic.center);
			newColorSub.closeCallback = onRequestGenerate;
			openSubState(newColorSub);
		}
		else
		{
			if (_hud.nextBumper == null)
				_hud.nextBumper = _bg.weightedGenerate();
			saveGame(); // NOTE: do I maybe want to do this in the base class, though?
		}
	}

	/** Called when the board is asking for a bumper to launch. **/
	function onLaunch(cb:BumperCallback)
	{
		FlxG.sound.play(AssetPaths.launch__wav);
		var retval = _hud.nextBumper != null ? _hud.nextBumper : _bg.weightedGenerate();
		_hud.nextBumper = null;
		_hud.score += addScore(5, _player.multStack);
		cb(retval);
	}

	/** Called when a match is formed. **/
	function onMatch(chain:Int, combo:Int, bumpers:Array<Bumper>)
	{
		var bonus = ((combo - 3) + (chain - 1)) * Math.floor(Math.pow(2, (chain - 1))) * 50;
		if (chain > 1)
			FlxG.sound.play(AssetPaths.chain__wav);
		else if (combo > 3)
			FlxG.sound.play(AssetPaths.combo__wav);
		else
			FlxG.sound.play(AssetPaths.match__wav);
		_hud.bonus = addScore(bonus, _player.multStack);
	}

	/** Called when a bumper is cleared. **/
	function onClear(chain:Int, _:Bumper)
	{
		FlxG.sound.play(AssetPaths.clear__wav);
		_hud.block++;
		_hud.score += addScore(10 * Math.floor(Math.pow(2, chain - 1)), _player.multStack);
	}

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
			FlxG.sound.play(AssetPaths.mselect__wav);
			_selectedColor = color;
			_boardClassic.selectMode();

			if (_paintCanBumper == null)
			{
				_paintCanBumper = new Bumper(_boardClassic.center.x - ((_boardClassic.bWidth + 2) * _boardClassic.sWidth / 2),
					_boardClassic.center.y + (_boardClassic.bHeight * _boardClassic.sHeight / 2), _selectedColor, Clearing);
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
				_paintCanCancelButton = new FlxButton(_boardClassic.center.x
					+ (_boardClassic.bWidth * _boardClassic.sWidth / 2)
					+ 20,
					_boardClassic.center.y
					+ (_boardClassic.bHeight * _boardClassic.sHeight / 2)
					+ 20, "X", onFieldCancel);
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
			onBumperSelect(null);

	/** Called when a bumper is selected, or the bumper selection is cancelled. **/
	function onBumperSelect(bumper:Bumper)
	{
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

	function onGameOver(animDone:Bool)
		if (!animDone)
		{
			FlxG.sound.play(AssetPaths.gameover__wav);
			if (gameType == "classic")
				clearGame();
		}

	override function serialize():DynamicAccess<Dynamic>
	{
		var retval = super.serialize();

		retval["jackpot"] = _jackpot;
		retval["nextColor"] = _nextColor;
		retval["nextColorEvery"] = _nextColorEvery;

		return retval;
	}

	override function deserialize(data:DynamicAccess<Dynamic>, ignoreGameName = false)
	{
		if (data["gameType"] == "classic")
		{
			while (_players.pop() != null) {}

			var playerData:Array<DynamicAccess<Dynamic>> = data["players"];
			for (player in playerData)
			{
				var board = new ClassicBoard(0, 0);
				board.deserialize(player["board"]);
				_players.push({
					board: board,
					multStack: player["multStack"]
				});
			}

			_hud = new ClassicHUD();
			_hud.deserialize(data["hud"]);
		}

		_jackpot = data["jackpot"];
		_nextColor = data["nextColor"];
		_nextColorEvery = data["nextColorEvery"];

		super.deserialize(data, ignoreGameName);
	}
}
