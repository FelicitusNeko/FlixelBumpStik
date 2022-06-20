package components.classic;

import boardObject.Bumper;
import components.Board;
import components.classic.ClassicHUD;
import flixel.FlxG;

class ClassicGameState extends GameState
{
	/** The value of the All Clear jackpot. **/
	private var _jackpot:Int = 0;

	/** The current number of available Paint Cans. **/
	private var _paintCans:Int = 0;

	/** The score target for the next Paint Can. **/
	private var _paintCansNext:Int = 1000;

	/** How much the score target for the next Paint Can will be incremented when it is hit. **/
	private var _paintCansIncrement:Int = 1500;

	/** The number of bumpers to clear to add a new color. **/
	private var _nextColor:Int = 100;

	/** A shortcut to cast `_hud` as `ClassicHUD`. **/
	private var _hudClassic(get, never):ClassicHUD;

	/** A shortcut to cast `_board` as `ClassicBoard`. **/
	private var _boardClassic(get, never):ClassicBoard;

	/** The current selected color during a Paint Can event. **/
	private var _selectedColor:Color;

	/** Whether the next bumper is selected during a Paint Can event. **/
	private var _isNextSelected = false;

	override function create()
	{
		_players.push({
			score: 0,
			block: 0,
			multStack: [1],
			board: new ClassicBoard(0, 0),
			nextBumper: _bg.weightedGenerate()
		});

		_hud = new ClassicHUD();
		_hudClassic.onPaintCanClick.add(onPaintCanClick);

		_boardClassic.onRequestGenerate.add(onRequestGenerate);
		_boardClassic.onMatch.add(onMatch);
		_boardClassic.onClear.add(onClear);
		_boardClassic.onLaunchBumper.add(onLaunch);
		_boardClassic.onBumperSelect.add(onBumperSelect);

		super.create();
	}

	inline function get__hudClassic()
	{
		return cast(_hud, ClassicHUD);
	}

	inline function get__boardClassic()
	{
		return cast(_player.board, ClassicBoard);
	}

	function _addScore(addScore:Int)
	{
		if (addScore == 0)
			return 0;

		_jackpot += addScore;
		var modAddScore = GameState.addScore(_player, addScore);
		_hud.score += modAddScore;
		if (_player.score >= _paintCansNext)
		{
			_hudClassic.paintCans = ++_paintCans;
			_paintCansNext += _paintCansIncrement;
			_paintCansIncrement += 500;
			trace("Awarding paint can; next at " + _paintCansNext);
		}
		return modAddScore;
	}

	function onPaintCanClick()
	{
		if (_paintCans > 0)
		{
			trace("Trying to use a Paint Can (have " + _paintCans + ")");
		}
	}

	function onRequestGenerate()
	{
		if (_player.block >= _nextColor && _bg.colors < 6)
		{
			_bg.colors++;
			_nextColor += 150;
			_player.multStack[0] += .2;
			trace("Adding new colour; now at " + _bg.colors);
		}
		if (_player.board.bCount <= 0 && _jackpot > 0)
		{
			var mJackpot = _addScore(_jackpot);
			_jackpot = 0;
			trace("Awarding jackpot of " + mJackpot);
		}
		if (_player.nextBumper == null)
			_player.nextBumper = _hud.nextBumper = _bg.generate();
	}

	function onLaunch(cb:BumperCallback)
	{
		var retval = _hud.nextBumper != null ? _hud.nextBumper : _bg.generate();
		_player.nextBumper = _hud.nextBumper = null;
		_addScore(5);
		cb(retval);
	}

	function onMatch(chain:Int, combo:Int)
	{
		var bonus = ((combo - 3) + (chain - 1)) * Math.floor(Math.pow(2, (chain - 1))) * 50;
		// TODO: display bonus on HUD
		_addScore(bonus);
	}

	function onClear(chain:Int)
	{
		_hud.block = ++_player.block;
		_addScore(10 * Math.floor(Math.pow(2, chain - 1)));
	}

	inline function onBumperSelect(bumper:Bumper)
	{
		bumper.bColor = _selectedColor;
		_selectedColor = None;
		_isNextSelected = false;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (_selectedColor != None)
		{
			#if mobile
			var touch = FlxG.touches.getFirst();
			var justPressed = false,
				justReleased = false,
				position:FlxPoint = new FlxPoint(0, 0);

			if (touch != null)
			{
				justPressed = touch.justPressed;
				justReleased = touch.justReleased;
				position = touch.getWorldPosition();
			}
			#else
			var justPressed = FlxG.mouse.justPressed;
			var justReleased = FlxG.mouse.justReleased;
			var position = FlxG.mouse.getWorldPosition();
			#end

			if (justPressed)
				_isNextSelected = _player.nextBumper.overlapsPoint(position);
			if (justReleased && _isNextSelected && _player.nextBumper.overlapsPoint(position))
			{
				_player.nextBumper.bColor = _selectedColor;
				_selectedColor = None;
				_isNextSelected = false;
				_boardClassic.endPaint();
			}
		}
	}
}
