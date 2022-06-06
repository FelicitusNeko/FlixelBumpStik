import Bumper.Color;
import Bumper.Direction;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;

/** The collection of possible game states. **/
enum BoardSM
{
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

class Board extends FlxTypedGroup<FlxBasic>
{
	/** The board's width, in grid units. **/
	public var bWidth(default, null):Int = 5;

	/** The board's height, in grid units. **/
	public var bHeight(default, null):Int = 5;

	// TODO: make sWidth and sHeight dynamic based on asset sizes

	/** The width of each space on the board, in pixels. **/
	public var sWidth(default, null):Float = 64;

	/** The height of each space on the board, in pixels. **/
	public var sHeight(default, null):Float = 64;

	/** The center point of this board. **/
	public var center(get, never):FlxPoint;

	/** The collection of board spaces. **/
	private var _spaces = new FlxTypedGroup<BoardSpace>();

	/** The collection of bumpers in play. **/
	private var _bumpers = new FlxTypedGroup<Bumper>();

	/** The collection of launchers in play. **/
	private var _launchers = new FlxTypedGroup<Launcher>();

	/** The number of seconds to wait before the next action should take place. **/
	private var _delay:Float = 0;

	/** The current state of the board. **/
	public var boardSM(default, null):BoardSM = Idle;

	public function new()
	{
		super();

		add(_spaces);
		for (x in 0...bWidth)
			for (y in 0...bHeight)
				_spaces.add(new BoardSpace(x * sWidth, y * sHeight));

		for (dir in [Direction.Down, Direction.Left, Direction.Up, Direction.Right])
		{
			var ox:Float = 0, oy:Float = 0, count:Int = 0;
			switch (dir)
			{
				case Down:
					oy = -sHeight;
					count = cast(bWidth, Int);
				case Left:
					ox = sWidth * bWidth;
					count = cast(bHeight, Int);
				case Up:
					oy = sHeight * bHeight;
					count = cast(bWidth, Int);
				case Right:
					ox = -sWidth;
					count = cast(bHeight, Int);
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
		add(_bumpers);
		add(_launchers);

		boardSM = Moving;
	}

	function get_center()
	{
		return new FlxPoint(bWidth * sWidth / 2, bHeight * sHeight / 2);
	}

	/**
		Set up a board state test.
		@param test The test number to run.
	**/
	private function setupTest(test:Int)
	{
		var autoLaunch = true;

		switch (test)
		{
			case 0: // Stationary bumper collision test ✔️
				putBumperAt(4, 3, Color.Green);
				putBumperAt(1, 3, Color.Red, Direction.Right);
			case 1: // Head-on collision test ✔️
				putBumperAt(0, 1, Color.Red, Direction.Right);
				putBumperAt(4, 1, Color.Blue, Direction.Left);
			case 2: // Cross-collision test #1 - both shifting on same frame ✔️?
				putBumperAt(0, 1, Color.Red, Direction.Right);
				putBumperAt(2, 4, Color.Blue, Direction.Up);
			case 3: // Cross-collision test #2 - shifting on different frame ✔️
				putBumperAt(0, 1, Color.Red, Direction.Right);
				var halfBumper = putBumperAt(2, 4, Color.Blue, Direction.Up);
				halfBumper.y -= halfBumper.height / 2;
			case 4: // Launch test ✔️
				var lbumper = putBumperAt(-40, -40, Color.Blue, Direction.Right);
				_launchers.getFirstAlive().launchBumper(lbumper);
				autoLaunch = false;
			case 5: // Driveby test #1 - horizontal ✔️
				putBumperAt(0, 1, Color.Blue, Direction.Right);
				putBumperAt(4, 2, Color.Red, Direction.Left);
			case 6: // Driveby test #2 - vertical ✔️
				putBumperAt(1, 0, Color.Blue, Direction.Down);
				putBumperAt(2, 4, Color.Red, Direction.Up);
		}
		if (autoLaunch)
			_bumpers.forEachAlive(bumper ->
			{
				if (bumper.direction != Direction.None)
					bumper.startMoving(bumper.direction);
			});
	}

	/**
		Creates a new bumper and puts it at the given grid coordinates.
		@param x The horizontal board grid coordinate.
		@param y The vertical board grid coordinate.
		@param color The color of the bumper.
		@param dir Optional. The direction of the bumper. Defaults to `Direction.None`.
		@return The new bumper.
	**/
	public function putBumperAt(x:Int, y:Int, color:Color, dir:Direction = Direction.None)
	{
		var bumper = new Bumper(x * sWidth, y * sHeight, color, dir);
		_bumpers.add(bumper);
		return bumper;
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
		Determines which bumper is located at the given board X and Y grid spaces. May only be used while the board is not in motion.
		@param x The X grid coordinate on the board.
		@param y The Y grid coordinate on the board.
		@return The bumper found at the given board grid coordinates, or `null` if there is none or if the board is in motion.
	**/
	public function bumperAt(x:Int, y:Int):Bumper
	{
		if (boardSM != Moving)
			for (bumper in _bumpers)
			{
				if (bumper.boardX == x && bumper.boardY == y)
					return bumper;
			}
		return null;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (boardSM)
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
							&& (bumper.frontX < 0 || bumper.frontY < 0 || bumper.frontX >= bWidth || bumper.frontY >= bHeight))
						{
							var wasLaunched = bumper.launchDirection != Direction.None;
							bumper.snapToPos();
							if (wasLaunched)
								bumper.startMoving();
						}
					}
					else
					{
						if (bumper.forwardX < 0 || bumper.forwardY < 0 || bumper.forwardX >= bWidth || bumper.forwardY >= bHeight)
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
					// trace("Done moving");
					boardSM = Clearing;
				}
			default:
		}
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
		@param bspr The bumper's overlapping sprite.
		@param space The board space's overlapping sprite.
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

	/**
		This function checks for overlaps between a bumper and a launcher.
		@param bspr The bumper's overlapping sprite.
		@param lspr The launcher's overlapping sprite.
	**/
	private function bumperToLauncher(bspr:FlxSprite, lspr:FlxSprite)
	{
		if (!bspr.alive || !lspr.alive)
			return;

		var bumper = spriteToBumper(bspr), launcher = spriteToLauncher(lspr);
		if (bumper == null || launcher == null)
			return;

		if (launcher.launching != bumper)
		{
			// trace("Bumper " + bumper.ID + " colliding with launcher " + launcher.ID);
			bumper.snapToPos();
		}
	}
}
