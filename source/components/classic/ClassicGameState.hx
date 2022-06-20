package components.classic;

import Board.BumperCallback;
import components.classic.ClassicHUD;

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

	override function create()
	{
		_players.push({
			score: 0,
			block: 0,
			multStack: [1],
			board: new Board(0, 0),
			nextBumper: _bg.weightedGenerate()
		});

		_hud = new ClassicHUD();
		_hudClassic.onPaintCanClick.add(onPaintCanClick);

		var board = _player.board;
		board.onRequestGenerate.add(onRequestGenerate);
		board.onMatch.add(onMatch);
		board.onClear.add(onClear);
		// board.onLaunchBumper = onLaunch;
		board.onLaunchBumper.add(onLaunch);

		super.create();
	}

	function get__hudClassic()
	{
		return cast(_hud, ClassicHUD);
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
}
