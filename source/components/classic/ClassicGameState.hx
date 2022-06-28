package components.classic;

import boardObject.Bumper;
import components.Board;
import components.classic.ClassicHUD;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;

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

	/** A shortcut to cast `_hud` as `ClassicHUD`. **/
	private var _hudClassic(get, never):ClassicHUD;

	/** A shortcut to cast `_board` as `ClassicBoard`. **/
	private var _boardClassic(get, never):ClassicBoard;

	/** The current selected color during a Paint Can event. **/
	private var _selectedColor:Color = None;

	override function create()
	{
		_players.push({
			board: new ClassicBoard(0, 0),
			multStack: [1]
		});

		_hud = new ClassicHUD();
		_hudClassic.onPaintCanGet.add((_) -> FlxG.sound.play(AssetPaths.paintcan__wav));
		_hudClassic.onPaintCanClick.add(onPaintCanClick);
		_hudClassic.onNextBumperClick.add(onBumperSelect);

		_boardClassic.onRequestGenerate.add(onRequestGenerate);
		_boardClassic.onMatch.add(onMatch);
		_boardClassic.onClear.add(onClear);
		_boardClassic.onLaunchBumper.add(onLaunch);
		_boardClassic.onBumperSelect.add(onBumperSelect);
		_boardClassic.onGameOver.add(() -> FlxG.sound.play(AssetPaths.gameover__wav));

		super.create();

		// var test = new FlxButton(0, 0, "Test", () ->
		// {
		// 	_hudClassic.paintCans = ++_paintCans;
		// });
		// test.scrollFactor.set(0, 0);
		// add(test);
	}

	inline function get__hudClassic()
	{
		return cast(_hud, ClassicHUD);
	}

	inline function get__boardClassic()
	{
		return cast(_player.board, ClassicBoard);
	}

	override function addScore(add:Int, multStack:Array<Float> = null):Int
	{
		if (add == 0)
			return 0;

		_jackpot += add;
		var modAdd = super.addScore(add, multStack == null ? _player.multStack : [1]);

		return modAdd;
	}

	function onPaintCanClick()
	{
		if (_selectedColor == None)
		{
			FlxG.sound.play(AssetPaths.mselect__wav);
			var bumperSize = new FlxPoint(_hud.nextBumper.width, _hud.nextBumper.height).scale(.5);
			var paintDialog = new PaintCanSubstate(_boardClassic.center.subtractPoint(bumperSize));
			paintDialog.onDialogResult.add(onColorSelect);
			openSubState(paintDialog);
		}
	}

	function onRequestGenerate()
	{
		if (_player.board.bCount <= 0 && _jackpot > 0)
		{
			FlxG.sound.play(AssetPaths.allclear__wav);
			var mJackpot = addScore(_jackpot);
			_jackpot = 0;
			trace("Awarding jackpot of " + mJackpot);
			openSubState(new AllClearSubstate(mJackpot, _boardClassic.center));
			_hud.bonus = mJackpot;
		}
		if (_hud.block >= _nextColor && _bg.colors < 6)
		{
			FlxG.sound.play(AssetPaths.levelup__wav);
			_nextColor += 150;
			_player.multStack[0] += .2;
			openSubState(new NewColorSubstate(BumperGenerator.colorOpts[_bg.colors++], _boardClassic.center));
			trace("Adding new colour; now at " + _bg.colors);
		}
		if (_hud.nextBumper == null)
			_hud.nextBumper = _bg.generate();
	}

	function onLaunch(cb:BumperCallback)
	{
		FlxG.sound.play(AssetPaths.launch__wav);
		var retval = _hud.nextBumper != null ? _hud.nextBumper : _bg.generate();
		_hud.nextBumper = null;
		_hud.score += addScore(5);
		cb(retval);
	}

	function onMatch(chain:Int, combo:Int)
	{
		var bonus = ((combo - 3) + (chain - 1)) * Math.floor(Math.pow(2, (chain - 1))) * 50;
		if (chain > 1)
			FlxG.sound.play(AssetPaths.chain__wav);
		else if (combo > 3)
			FlxG.sound.play(AssetPaths.combo__wav);
		else
			FlxG.sound.play(AssetPaths.match__wav);
		// TODO: display bonus on HUD
		_hud.bonus = addScore(bonus);
	}

	function onClear(chain:Int)
	{
		FlxG.sound.play(AssetPaths.clear__wav);
		_hud.block++;
		_hud.score += addScore(10 * Math.floor(Math.pow(2, chain - 1)));
	}

	function onColorSelect(color:Color)
	{
		if (color != None && _selectedColor == None)
		{
			FlxG.sound.play(AssetPaths.mselect__wav);
			_selectedColor = color;
			_boardClassic.startPaint();

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
					+ 20, "X", () -> onBumperSelect(null));
				_paintCanCancelButton.loadGraphic(AssetPaths.button__png, true, 20, 20);
				_paintCanCancelButton.scale.set(2, 2);
				_paintCanCancelButton.scrollFactor.set(1, 1);
				add(_paintCanCancelButton);
			}
			else
				_paintCanCancelButton.revive();
		}
	}

	function onBumperSelect(bumper:Bumper)
	{
		if (_selectedColor != None)
		{
			if (bumper != null)
			{
				FlxG.sound.play(AssetPaths.mselect__wav);
				_hudClassic.paintCans--;
				bumper.bColor = _selectedColor;
			}
			else
			{
				FlxG.sound.play(AssetPaths.mback__wav);
			}
			_paintCanBumper.kill();
			_paintCanCancelButton.kill();
			_selectedColor = None;
			_boardClassic.endPaint(_selectedColor == None);
		}
	}
}
