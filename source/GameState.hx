import Bumper.Color;
import Bumper.Direction;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import openfl.system.System;

/** The collection of possible game states. **/
enum GameSM
{
	/** The game is being initialized. **/
	Starting;

	/** The game is waiting for user input. **/
	Idle;

	/** Bumper movement is being processed. **/
	Moving;

	/** Bumpers are being cleared from the field. **/
	Clearing;

	/** In certain game modes, Special can be used for nonstandard states. **/
	Special(x:Int);

	/** The game is over. **/
	GameOver;
}

abstract class GameState extends FlxState
{
	/** The player's current score. **/
	public var score(default, null):Int = 0;

	/** The player's current count of bumpers sticked (cleared). **/
	public var block(default, null):Int = 0;

	/** The current state of the game. **/
	public var gameSM(default, null):GameSM = Starting;

	/** The next bumper to be put into play. **/
	private var _nextBumper:Bumper = null;

	/** The collection of board spaces. **/
	private var _spaces = new FlxTypedGroup<BoardSpace>();

	/** The collection of bumpers in play. **/
	private var _bumpers = new FlxTypedGroup<Bumper>();

	/** The number of seconds to wait before the next action should take place. **/
	private var _delay:Float = 0;

	override function create()
	{
		add(_spaces);
		for (x in 0...5)
			for (y in 0...5)
			{
				_spaces.add(new BoardSpace(x * 64, y * 64));
			}

		_nextBumper = new Bumper(550, 400, Color.Blue);
		add(_nextBumper);

		add(_bumpers);
		// Stationary bumper collision test ✔️
		// _bumpers.add(new Bumper(320, 64, Color.Green, Direction.None));

		// Head-on collision test ✔️
		// _bumpers.add(new Bumper(0, 64, Color.Red, Direction.Right));
		// _bumpers.add(new Bumper(256, 64, Color.Blue, Direction.Left));

		// Cross-collision test #1 - both shifting on same frame ❌
		_bumpers.add(new Bumper(-128, 64, Color.Red, Direction.Right));
		_bumpers.add(new Bumper(64, 320, Color.Blue, Direction.Up));

		// Cross-collision test #2 - shifting on different frame ✔️
		// _bumpers.add(new Bumper(-100, 64, Color.Red, Direction.Right));
		// _bumpers.add(new Bumper(64, 320, Color.Blue, Direction.Up));

		_bumpers.forEachAlive(bumper ->
		{
			// bumper.snapToPos();
			if (bumper.direction != Direction.None)
				bumper.startMoving(bumper.direction);
		});
		gameSM = GameSM.Moving;

		// TODO: this should be [tile width/height] / 2 * [board width/height]
		FlxG.camera.focusOn(new FlxPoint(160, 160));

		super.create();
	}

	override function update(elapsed:Float)
	{
		_delay -= elapsed;
		if (_delay < 0)
		{
			// TODO: do movement things based on the negative of _delay
			_delay = 0;
		}

		switch (gameSM)
		{
			case Moving:
				FlxG.overlap(_bumpers, _bumpers, bumperBump);
				FlxG.overlap(_bumpers, _spaces, bumperToSpace);
				var isSomethingMoving = false;
				for (bumper in _bumpers)
					if (isSomethingMoving = bumper.isMoving)
						break;
				if (!isSomethingMoving)
				{
					trace("Done moving");
					gameSM = GameSM.Clearing;
				}
			default:
		}

		#if debug
		if (FlxG.keys.anyJustPressed([ESCAPE]))
			System.exit(0);
		#end

		super.update(elapsed);
	}

	/** 
		Looks for a bumper based on a given sprite.
		@param bspr The sprite to look for.
		@return The bumper to which the sprite belongs, or `null` if none was found.
	**/
	private function spriteToBumper(bspr:FlxSprite)
	{
		for (bumper in _bumpers)
		{
			if (bumper.has(bspr))
				return bumper;
		}
		return null;
	}

	/**
		Determines which bumpers are located at the given board X and Y grid spaces.
		@param x The X grid coordinate on the board.
		@param y The Y grid coordinate on the board.
		@param exclude Optional. Excludes this bumper from the list to be returned.
		@return The list of bumpers found within the given board grid coordinates.
	**/
	public function bumpersAt(x:Int, y:Int, exclude:Bumper = null)
	{
		var retval:Array<Bumper> = [];
		_bumpers.forEach(bumper ->
		{
			if (bumper != exclude && bumper.isAt(x, y))
				retval.push(bumper);
		});
		return retval;
	}

	/**
		This function checks for overlaps between bumpers.
		@param lh One of the overlapping sprites.
		@param rh The other overlapping sprite.
	**/
	private function bumperBump(lh:FlxSprite, rh:FlxSprite)
	{
		if (!lh.alive || !rh.alive)
			return;

		// trace("Collision between " + lh.ID + " and " + rh.ID);
		var blh = spriteToBumper(lh), brh = spriteToBumper(rh);
		if (blh == brh || blh == null || brh == null)
			return;

		if (blh.hasShifted && brh.hasShifted)
		{
			trace("Double-shift collision");
			if (blh.frontX == brh.lfFrontX && blh.frontY == brh.lfFrontY)
				blh.snapToPos();
			else
				brh.snapToPos();
		}
		else
			for (bumper in [blh, brh])
				if (bumper.hasShifted)
					bumper.snapToPos();
	}

	/**
		This function checks for overlaps between a bumper and a board space.
		@param lh The bumper's overlapping sprite.
		@param rh The board space's overlapping sprite.
	**/
	private function bumperToSpace(lh:FlxSprite, rh:BoardSpace)
	{
		if (!lh.alive)
			return;

		var blh = spriteToBumper(lh);
		if (blh == null)
			return;

		if (!blh.isMoving)
			return;
		if (rh.boardX == blh.frontX && rh.boardY == blh.frontY)
		{
			if (rh.reservedFor == null)
				rh.reservedFor = blh;
			else if (rh.reservedFor != blh)
				blh.snapToPos();
		}
		else if (rh.reservedFor == blh)
			rh.reservedFor = null;
	}
}
