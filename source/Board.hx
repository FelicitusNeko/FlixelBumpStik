package;

import boardObject.BoardObject;
import boardObject.BoardSpace;
import boardObject.Bumper;
import boardObject.Launcher;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import haxe.Timer;

class Board extends FlxTypedGroup<FlxBasic>
{
	/** The board's top-left corner, excluding Launchers. **/
	public var origin(default, null):FlxPoint;

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

	/** The state machine for this board. **/
	private var _fsm:FSM;

	/** The currently selected launcher. **/
	private var _selectedLauncher:Launcher = null;

	/** The current chain progression in steps. **/
	public var curChain(default, null):Int = 0;

	public var onRequestGenerate:Void->Void = null;
	public var onLaunchBumper:Void->Bumper = null;
	public var onMatch:(Int, Int) -> Void = null;
	public var onClear:Void->Void = null;

	public function new(x:Float = 0, y:Float = 0)
	{
		super();
		origin = new FlxPoint(x, y);

		add(_spaces);
		for (x in 0...bWidth)
			for (y in 0...bHeight)
				_spaces.add(new BoardSpace(x * sWidth, y * sHeight, this));

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
					_launchers.add(new Launcher(ox + (z * sWidth), oy, dir, this));
				else
					_launchers.add(new Launcher(ox, oy + (z * sHeight), dir, this));
			}
		}
		add(_bumpers);
		add(_launchers);

		_fsm = new FSM(fsmIdle);

		// setupTest(9);

		// trace((bWidth + 2) * sWidth, (bHeight + 2) * sHeight);
	}

	function get_center()
	{
		return new FlxPoint(bWidth * sWidth / 2, bHeight * sHeight / 2).addPoint(origin);
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
			case 7: // Match test #1 - vertical ✔️
				putBumperAt(4, 0, Green, None);
				putBumperAt(4, 1, Blue, None);
				putBumperAt(0, 2, Blue, Right);
				putBumperAt(4, 3, Blue, None);
				putBumperAt(4, 4, Red, None);
			case 8: // Match test #2 - horizontal ✔️
				putBumperAt(0, 4, Green, None);
				putBumperAt(1, 4, Blue, None);
				putBumperAt(2, 0, Blue, Down);
				putBumperAt(3, 4, Blue, None);
				putBumperAt(4, 4, Red, None);
			case 9: // Corner collision ❌
				// BUG: Rounding/precision issues causing collisions where they shouldn't happen
				putBumperAt(2, 4, Blue, Right);
				putBumperAt(4, 4, Blue, Right);
				putBumperAt(2, 0, Green, Down);
		}
		if (autoLaunch)
			_bumpers.forEachAlive(bumper ->
			{
				if (bumper.direction != Direction.None)
					bumper.startMoving(bumper.direction);
			});

		_fsm.activeState = fsmMoving;
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
		var bumper = new Bumper(x * sWidth, y * sHeight, color, dir, None, this);
		_bumpers.add(bumper);
		return bumper;
	}

	/** 
		Looks for a board object based on a given sprite.
		@param bspr The sprite to look for.
		@param list The list of objects to retreve from.
		@return The board object to which the sprite belongs, or `null` if none was found.
	**/
	private function spriteTo<T:BoardObject>(spr:FlxSprite, list:FlxTypedGroup<T>):T
	{
		for (thing in list)
		{
			if (thing.has(spr))
				return thing;
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
		Determines which bumper is located at the given board X and Y grid spaces.
		Should only be used while the board is not in motion; may be unreliable otherwise.
		@param x The X grid coordinate on the board.
		@param y The Y grid coordinate on the board.
		@return The bumper found at the given board grid coordinates, or `null` if there is none.
	**/
	public function bumperAt(x:Int, y:Int):Bumper
	{
		for (bumper in _bumpers)
		{
			if (bumper.boardX == x && bumper.boardY == y && bumper.alive)
				return bumper;
		}
		return null;
	}

	/**
		Determines which launcher, if any, is located at the given `FlxPoint` coordinates.
		@param pt The world position to check at.
		@return The launcher at that point, or `null` if there is none.
	**/
	public function launcherAtPoint(pt:FlxPoint):Launcher
	{
		for (launcher in _launchers)
			if (launcher.overlapsPoint(pt))
				return launcher;
		return null;
	}

	public function spaceAt(x:Int, y:Int)
	{
		for (space in _spaces)
			if (space.boardX == x && space.boardY == y)
				return space;

		return null;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_fsm.update(elapsed);
	}

	/** State machine call for idle state. **/
	private function fsmIdle(elapsed:Float)
	{
		if (_fsm.justChanged) // If the state just changed to idle:
		{
			if (onRequestGenerate != null)
				onRequestGenerate(); // Request that a new next bumper be generated
			curChain = 0; // Reset chain to zero
		}

		if (FlxG.mouse.justMoved || _fsm.justChanged) // If the mouse just moved, or the state just changed:
		{
			if (FlxG.mouse.pressed && _selectedLauncher != null) // If the mouse is held and there is a selected bumper:
			{
				// If the mouse is over the selected bumper, use Selected state; if not, use SelectedNotHovering
				_selectedLauncher.state = _selectedLauncher == launcherAtPoint(FlxG.mouse.getWorldPosition()) ? Selected : SelectedNotHovering;
			}
			else // If the mouse is not held or there's no selected bumper:
			{
				var launcher = launcherAtPoint(FlxG.mouse.getWorldPosition()); // Determine if there's a bumper under the cursor
				if (_selectedLauncher != launcher) // If what's under the cursor is not the selected launcher:
				{
					if (_selectedLauncher != null && _selectedLauncher.state != Blocked) // If there is a previously selected launcher and it's not Blocked:
						_selectedLauncher.state = Open; // Set its state to Open
					_selectedLauncher = launcher; // Assign what's under the bumper as the selected launcher
					if (_selectedLauncher != null && _selectedLauncher.state != Blocked) // If there is a newly selected launcher and it's not Blocked:
						_selectedLauncher.state = Hovering; // Set its state to Hovering
				}
			}
		}

		if (FlxG.mouse.justPressed && _selectedLauncher != null && _selectedLauncher.state == Hovering) // If the mouse was just clicked on a launcher that's in Hovering state:
		{
			_selectedLauncher.state = Selected; // Set its state to Selected
		}
		if (FlxG.mouse.justReleased && _selectedLauncher != null && _selectedLauncher.state == Selected) // If the mouse was just released from a launcher that's in Selected state:
		{
			// _selectedLauncher.state = Open;
			var bumper = onLaunchBumper != null ? onLaunchBumper() : new Bumper(0, 0, Blue,
				Right); // Get the next bumper from the game state (if there's no callback, just make a bumper)
			_bumpers.add(bumper); // Add the bumper to the board collection
			_selectedLauncher.launchBumper(bumper); // Launch the bumper from the launcher
			_launchers.forEach(launcher -> launcher.enabled = false); // Disable all the launchers
			_fsm.activeState = fsmMoving; // Set the board state to Moving

			_selectedLauncher = null; // Clear the launcher selection
		}
	}

	private function fsmMoving(elapsed:Float)
	{
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
			_fsm.activeState = fsmChecking;
		}
	}

	/** Checks for Bumper Stickers, and marks bumpers to be cleared if any have been formed. **/
	private function fsmChecking(elapsed:Float)
	{
		_fsm.activeState = null;
		var clearCount:Int = 0;
		function clear(x:Int, y:Int, count:Int, horizontal:Bool)
		{
			for (_ in 0...count)
			{
				if (horizontal)
					x--;
				else
					y--;
				var bumper = bumperAt(x, y);
				if (bumper != null && bumper.markForClear())
					clearCount++;
			}
		}

		function check(horizontal:Bool)
		{
			for (y in 0...(horizontal ? bHeight : bWidth))
			{
				var streakColor:Color = None, streakLength:Int = 0;
				for (x in 0...(horizontal ? bWidth : bHeight))
				{
					var bumper = horizontal ? bumperAt(x, y) : bumperAt(y, x);
					if (bumper != null && bumper.bColor == streakColor)
						streakLength++;
					else
					{
						if (streakLength >= 3)
							horizontal ? clear(x, y, streakLength, horizontal) : clear(y, x, streakLength, horizontal);
						streakColor = bumper != null ? bumper.bColor : None;
						streakLength = streakColor == None ? 0 : 1;
					}
				}
				if (streakLength >= 3)
					horizontal ? clear(bWidth, y, streakLength, horizontal) : clear(y, bHeight, streakLength, horizontal);
			}
		}

		for (horizontal in [true, false])
			check(horizontal);

		if (clearCount > 0)
		{
			_delay = .5;
			// TODO: play sound
			curChain++;
			if (onMatch != null)
				onMatch(curChain, clearCount);
			_fsm.activeState = fsmClearing;
		}
		else
		{
			var launchersAvailable = 0;
			_launchers.forEachAlive(launcher ->
			{
				launcher.enabled = true;
				if (launcher.state != Blocked)
					launchersAvailable++;
			});
			if (launchersAvailable > 0)
				_fsm.activeState = fsmIdle;
			else
			{
				// TODO: Game over
				_bumpers.forEach(bumper -> bumper.direction = GameOver);
				_fsm.activeState = null;
			}
		}
	}

	private function fsmClearing(elapsed:Float)
	{
		_delay -= elapsed;
		if (_delay <= 0)
		{
			for (y in 0...bHeight)
				for (x in 0...bWidth)
				{
					var bumper = bumperAt(x, y);
					if (bumper != null && bumper.direction == Clearing)
					{
						bumper.kill();
						_delay += .15;
						return;
					}
				}

			_delay = 0;

			var deadBuffer:Array<Bumper> = [];
			_bumpers.forEachDead(bumper -> _bumpers.remove(bumper));
			for (bumper in deadBuffer)
			{
				if (onClear != null)
					onClear();
				_bumpers.remove(bumper);
				bumper.destroy();
			}

			for (space in _spaces)
				space.reservedFor = null;
			if (_bumpers.length == 0)
			{
				// TODO: All Clear
				_launchers.forEach(launcher -> launcher.enabled = true);
				_fsm.activeState = fsmIdle;
			}
			else
			{
				FlxG.overlap(_bumpers, _spaces, bumperToSpace);
				_fsm.activeState = fsmMoving;
			}
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

		var blh = spriteTo(lh, _bumpers), brh = spriteTo(rh, _bumpers);
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
	private function bumperToSpace(bspr:FlxSprite, sspr:FlxSprite)
	{
		if (!bspr.alive)
			return;

		var bumper = spriteTo(bspr, _bumpers), space = spriteTo(sspr, _spaces);
		if (bumper == null || space == null)
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

		var bumper = spriteTo(bspr, _bumpers),
			launcher = spriteTo(lspr, _launchers);
		if (bumper == null || launcher == null)
			return;

		if (launcher.launching != bumper)
			bumper.snapToPos();
	}
}
