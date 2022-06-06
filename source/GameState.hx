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

	/** The board's width, in grid units. **/
	public var width(default, null):Int = 5;

	/** The board's height, in grid units. **/
	public var height(default, null):Int = 5;

	/** The next bumper to be put into play. **/
	private var _nextBumper:Bumper = null;

	/** The collection of board spaces. **/
	private var _spaces = new FlxTypedGroup<BoardSpace>();

	/** The collection of bumpers in play. **/
	private var _bumpers = new FlxTypedGroup<Bumper>();

	/** The collection of launchers in play. **/
	private var _launchers = new FlxTypedGroup<Launcher>();

	/** The number of seconds to wait before the next action should take place. **/
	private var _delay:Float = 0;

	override function create()
	{
		// TODO: make this dynamic based on asset sizes
		var sWidth:Float = 64, sHeight:Float = 64;

		add(_spaces);
		for (x in 0...width)
			for (y in 0...height)
				_spaces.add(new BoardSpace(x * sWidth, y * sHeight));

		_nextBumper = new Bumper(550, 400, Color.Blue);
		add(_nextBumper);

		add(_bumpers);

		for (dir in [Direction.Down, Direction.Left, Direction.Up, Direction.Right])
		{
			var ox:Float = 0, oy:Float = 0, count:Int = 0;
			switch (dir)
			{
				case Down:
					oy = -sHeight;
					count = cast(width, Int);
				case Left:
					ox = sWidth * width;
					count = cast(height, Int);
				case Up:
					oy = sHeight * height;
					count = cast(width, Int);
				case Right:
					ox = -sWidth;
					count = cast(height, Int);
				default:
			}

			for (z in 0...count)
			{
				if (dir == Up || dir == Down)
					_launchers.add(new Launcher(ox + (z * sWidth), oy, dir));
				else
					_launchers.add(new Launcher(ox, oy + (z * sHeight), dir));
			}
		}
		add(_launchers);

		// Stationary bumper collision test ✔️
		// _bumpers.add(new Bumper(320, 64, Color.Green, Direction.None));

		// Head-on collision test ✔️
		// _bumpers.add(new Bumper(0, 64, Color.Red, Direction.Right));
		// _bumpers.add(new Bumper(256, 64, Color.Blue, Direction.Left));

		// Cross-collision test #1 - both shifting on same frame ✔️?
		// _bumpers.add(new Bumper(sWidth * -2, sHeight, Color.Red, Direction.Right));
		// _bumpers.add(new Bumper(sWidth, sHeight * 5, Color.Blue, Direction.Up));

		// Cross-collision test #2 - shifting on different frame ✔️
		// _bumpers.add(new Bumper(-100, 64, Color.Red, Direction.Right));
		// _bumpers.add(new Bumper(64, 320, Color.Blue, Direction.Up));

		// Launch test ✔️
		var lbumper = new Bumper(-400, -400, Color.Blue, Direction.Right);
		_bumpers.add(lbumper);
		_launchers.getFirstAlive().launchBumper(lbumper);

		// Driveby test #1 - horizontal ✔️
		// _bumpers.add(new Bumper(0, sHeight * 1, Color.Blue, Direction.Right));
		// _bumpers.add(new Bumper(sWidth * 4, sHeight * 2, Color.Red, Direction.Left));

		// Driveby test #2 - vertical ✔️
		// _bumpers.add(new Bumper(sWidth * 1, 0, Color.Blue, Direction.Down));
		// _bumpers.add(new Bumper(sWidth * 2, sHeight * 4, Color.Red, Direction.Up));

		// _bumpers.forEachAlive(bumper ->
		// {
		// 	// bumper.snapToPos();
		// 	if (bumper.direction != Direction.None)
		// 		bumper.startMoving(bumper.direction);
		// });
		gameSM = GameSM.Moving;

		FlxG.camera.focusOn(new FlxPoint(width * (sWidth / 2), height * (sHeight / 2)));

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
				// FlxG.overlap(_bumpers, _launchers, bumperToLauncher);

				_bumpers.forEachAlive(bumper ->
				{
					if (bumper.isMoving)
					{
						if (!bumper.justLaunched
							&& bumper.hasShifted
							&& (bumper.frontX < 0 || bumper.frontY < 0 || bumper.frontX >= width || bumper.frontY >= height))
						{
							var wasLaunched = bumper.launchDirection != Direction.None;
							bumper.snapToPos();
							if (wasLaunched)
								bumper.startMoving();
						}
					}
					else
					{
						if (bumper.forwardX < 0 || bumper.forwardY < 0 || bumper.forwardX >= width || bumper.forwardY >= height)
							return;
						var bumpers = bumpersAt(bumper.forwardX, bumper.forwardY, bumper);
						for (chkBumper in bumpers)
							if (chkBumper.activeDirection != bumper.activeDirection || !chkBumper.isMoving)
								return;
						bumper.startMoving();
					}
				});

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

		#if (debug && sys)
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
		Looks for a launcher based on a given sprite.
		@param bspr The sprite to look for.
		@return The launcher to which the sprite belongs, or `null` if none was found.
	**/
	private function spriteToLauncher(lspr:FlxSprite)
	{
		for (launcher in _launchers)
		{
			if (launcher.has(lspr))
				return launcher;
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
		var boardSpace:BoardSpace = null;

		for (space in _spaces)
			if (space.boardX == x && space.boardY == y)
				boardSpace = space;
		if (boardSpace == null)
			return [];

		var retval:Array<Bumper> = [];
		_bumpers.forEach(bumper ->
		{
			if (bumper != exclude && boardSpace.overlaps(bumper))
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
	private function bumperToSpace(bspr:FlxSprite, space:BoardSpace)
	{
		if (!bspr.alive)
			return;

		var bumper = spriteToBumper(bspr);
		if (bumper == null)
			return;

		if (!bumper.isMoving)
			return;
		if (space.boardX == bumper.frontX && space.boardY == bumper.frontY)
		{
			if (space.reservedFor == null)
				space.reservedFor = bumper;
			else if (space.reservedFor != bumper)
				bumper.snapToPos();
		}
		else if (space.reservedFor == bumper)
			space.reservedFor = null;
	}

	private function bumperToLauncher(bspr:FlxSprite, lspr:FlxSprite)
	{
		if (!bspr.alive || !lspr.alive)
			return;

		var bumper = spriteToBumper(bspr), launcher = spriteToLauncher(lspr);
		if (bumper == null || launcher == null)
			return;

		if (launcher.launching != bumper)
		{
			trace("Bumper " + bumper.ID + " colliding with launcher " + launcher.ID);
			bumper.snapToPos();
		}
	}
}
