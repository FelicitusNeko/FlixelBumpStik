package;

import boardObject.Bumper;
import flixel.FlxG;
import flixel.FlxState;
import openfl.system.System;

/** Stats for each player. **/
typedef PlayerInstance =
{
	/** The player's current score. **/
	var score:Int;

	/** The player's current count of bumpers sticked (cleared). **/
	var block:Int;

	/** The player's current score multiplier stack. **/
	var multStack:Array<Float>;

	/** The board to be used for this player. **/
	var board:Board;

	/** The next bumper to be put into play. **/
	var nextBumper:Bumper;
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
				score: 0,
				block: 0,
				multStack: [1],
				board: new Board(0, 0),
				nextBumper: _bg.generate()
			});

			_player.board.onRequestGenerate = onRequestGenerate;
			_player.board.onLaunchBumper = onLaunch;
			_player.board.onMatch = onMatch;
			_player.board.onClear = onClear;
		}

		for (player in _players)
			add(player.board);

		if (_hud == null)
			_hud = new StandardHUD();

		_hud.nextBumper = _player.nextBumper;
		add(_hud);
		FlxG.camera.focusOn(_player.board.center.add(_hud.width / 2, 0));
		// TODO: figure out how to make the HUD not be affected by zoom
		// FlxG.camera.zoom = .9;

		super.create();
	}

	function addScore(addScore:Int)
	{
		// TODO: pre-mult addScore goes into jackpot
		var mult:Float = 1;
		for (factor in _player.multStack)
			mult *= factor;
		_hud.score = _player.score += Math.floor(addScore * mult);
	}

	function onRequestGenerate()
	{
		if (_player.nextBumper == null)
			_player.nextBumper = _hud.nextBumper = _bg.generate();
	}

	function onLaunch()
	{
		var retval = _hud.nextBumper != null ? _hud.nextBumper : _bg.generate();
		_player.nextBumper = _hud.nextBumper = null;
		addScore(5);
		return retval;
	}

	function onMatch(chain:Int, combo:Int)
	{
		var bonus = ((combo - 3) + (chain - 1)) * Math.floor(Math.pow(2, (chain - 1))) * 50;
		// TODO: display bonus on HUD
		addScore(bonus);
	}

	function onClear(chain:Int)
	{
		_hud.block = ++_player.block;
		addScore(10 * Math.floor(Math.pow(2, chain - 1)));
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
