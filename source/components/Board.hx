package components;

import boardObject.BoardObject;
import boardObject.BoardSpace;
import boardObject.Bumper;
import boardObject.Launcher;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import lime.app.Event;

typedef BumperCallback = Bumper->Void;

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

	/** The total width of the board, in pixels. **/
	public var tWidth(get, never):Float;

	/** The total height of the board, in pixels. **/
	public var tHeight(get, never):Float;

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
	private var _csm:CSM;

	/** The currently selected launcher. **/
	private var _selectedLauncher:Launcher = null;

	/** The current chain progression in steps. **/
	public var curChain(default, null):Int = 0;

	/** The current count of bumpers on the field. **/
	public var bCount(get, never):Int;

	/** Event that fires when the game requests that a next bumper be generated. **/
	public var onRequestGenerate(default, null) = new Event<Void->Void>();

	/**
		Event that fires when the next bumper is being launched.
		@param callback Function for the receiver to call to send along a bumper.
	**/
	public var onLaunchBumper(default, null) = new Event<BumperCallback->Void>();

	/**
		Event that fires when a match occurs.
		@param chain The chain step for this match.
		@param combo The number of bumpers matched.
	**/
	public var onMatch(default, null) = new Event<(Int, Int) -> Void>();

	/**
		Event that fires when a bumper clears.
		@param chain The chain step for this overall match.
	**/
	public var onClear(default, null) = new Event<Int->Void>();

	/** Event that fires when the game is over. **/
	public var onGameOver(default, null) = new Event<Void->Void>();

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

		_csm = new CSM(smIdle);
		_csm.addState("moving", smMoving);
		_csm.addState("checking", smChecking);
		_csm.addState("clearing", smClearing);
		_csm.addState("gameover", null);

		_csm.set("initial", "launch", "moving");
		_csm.set("moving", "stopped", "checking");
		_csm.set("checking", "match", "clearing");
		_csm.set("checking", "nomatch", "initial");
		_csm.set("checking", "gameover", "gameover");
		_csm.set("clearing", "cleared", "moving");
		_csm.set("clearing", "allclear", "initial");

		for (launcher in _launchers)
			launcher.onClick.add(onClickLauncher);

		// setupTest(10);
	}

	inline function get_tWidth()
	{
		return (bWidth + 2) * sWidth;
	}

	inline function get_tHeight()
	{
		return (bHeight + 2) * sHeight;
	}

	inline function get_center()
	{
		return new FlxPoint(bWidth * sWidth / 2, bHeight * sHeight / 2).addPoint(origin);
	}

	inline function get_bCount()
	{
		return _bumpers.countLiving();
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
			case 9: // Corner collision ✔️
				putBumperAt(2, 4, Blue, Right);
				putBumperAt(4, 4, Blue, Right);
				putBumperAt(2, 0, Green, Down);
			case 10: // Chain scoring (×3)
				putBumperAt(2, 2, Blue, Down);
				putBumperAt(2, 3, Blue, Up);
				putBumperAt(0, 2, Green, Left);
				putBumperAt(1, 2, Green, Left);
				putBumperAt(3, 2, Green, Left);
				putBumperAt(0, 0, Red, Up);
				putBumperAt(0, 1, Red, Up);
				putBumperAt(0, 3, Red, Up);
				var launcher = atPoint(_launchers, new FlxPoint(origin.x, origin.y).add(sWidth * 2.5, sHeight * 5.5));
				if (launcher != null)
					launcher.launchBumper(new Bumper(0, 0, Blue, Up));
				autoLaunch = false;
		}
		if (autoLaunch)
			_bumpers.forEachAlive(bumper ->
			{
				if (bumper.direction != Direction.None)
					bumper.startMoving(bumper.direction);
			});

		_csm.chain("launch");
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
		bumper.onClick.add(onClickBumper);
		_bumpers.add(bumper);
		return bumper;
	}

	/** 
		Looks for a board object based on a given sprite.
		@param list The list of objects to retreve from.
		@param bspr The sprite to look for.
		@return The board object to which the sprite belongs, or `null` if none was found.
	**/
	@:generic
	private function spriteTo<T:BoardObject>(list:FlxTypedGroup<T>, spr:FlxSprite):T
	{
		for (object in list)
			if (object.has(spr))
				return object;
		return null;
	}

	/**
		Determines which board object is located at the given board X and Y grid spaces.
		@param list The list of objects to retreve from.
		@param x The X grid coordinate on the board.
		@param y The Y grid coordinate on the board.
		@param mustBeAlive Optional. Whether the returned object must be alive. Default `true`
		@return The board object found at the given board grid coordinates, or `null` if there is none.
	**/
	@:generic
	public function atGrid<T:BoardObject>(list:FlxTypedGroup<T>, x:Int, y:Int, mustBeAlive = true):T
	{
		for (object in list)
			if (object.boardX == x && object.boardY == y && (!mustBeAlive || object.alive))
				return object;
		return null;
	}

	/**
		Temporary function for launcher functionality.
		@deprecated Currently only to be used for the `Launcher` class.
	**/
	public function bumperAt(x, y)
	{
		return atGrid(_bumpers, x, y);
	}

	/**
		Determines which board object, if any, is located at the given `FlxPoint` coordinates.
		@param list The list of objects to retreve from.
		@param pt The world position to check at.
		@param mustBeAlive Optional. Whether the returned object must be alive. Default `true`
		@return The board object at that point, or `null` if there is none.
	**/
	@:generic
	public function atPoint<T:BoardObject>(list:FlxTypedGroup<T>, pt:FlxPoint, mustBeAlive = true):T
	{
		for (object in list)
			if (object.overlapsPoint(pt) && (!mustBeAlive || object.alive))
				return object;

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
		var boardSpace:BoardSpace = atGrid(_spaces, x, y);
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
		Updates all member objects and runs the state machine.
		@param elapsed The number of seconds passed since the last frame.
	**/
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_csm.update(elapsed);
	}

	/** State machine call for idle state. **/
	private function smIdle(elapsed:Float)
	{
		if (_csm.justChanged) // If the state just changed to idle:
		{
			onRequestGenerate.dispatch(); // Request that a new next bumper be generated
			curChain = 0; // Reset chain to zero
		}
	}

	/** State machine call for moving state. **/
	private function smMoving(elapsed:Float)
	{
		FlxG.overlap(_bumpers, _bumpers, bumperBump);
		FlxG.overlap(_bumpers, _spaces, bumperToSpace);

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
			var dirOpts = BumperGenerator.dirOpts;
			_bumpers.sort((order, lhs, rhs) ->
			{
				if (lhs == null)
					order--;
				else if (rhs == null)
					order++;
				else if (lhs.direction == rhs.direction)
				{
					var lhFirst = 0, lhSecond = 0, rhFirst = 0, rhSecond = 0;
					switch (lhs.direction)
					{
						case Up:
							lhFirst = lhs.boardX;
							lhSecond = lhs.boardY;
							rhFirst = rhs.boardX;
							rhSecond = rhs.boardY;
						case Down:
							lhFirst = lhs.boardX;
							lhSecond = bHeight - lhs.boardY;
							rhFirst = rhs.boardX;
							rhSecond = bHeight - rhs.boardY;
						case Left:
							lhFirst = lhs.boardY;
							lhSecond = lhs.boardX;
							rhFirst = rhs.boardY;
							rhSecond = rhs.boardX;
						case Right:
							lhFirst = lhs.boardY;
							lhSecond = bWidth - lhs.boardX;
							rhFirst = rhs.boardY;
							rhSecond = bWidth - rhs.boardX;
						default:
					}
					if (lhFirst < rhFirst)
						order--;
					else if (lhFirst > rhFirst)
						order++;
					else if (lhSecond < rhSecond)
						order--;
					else if (lhSecond > rhSecond)
						order++;
					else
						trace("Sort error: bumpers of same direction, boardX, and boardY. Are they in the same place?");
				}
				else
				{
					var lhDir = dirOpts.indexOf(lhs.direction),
						rhDir = dirOpts.indexOf(rhs.direction);
					if (lhDir > rhDir)
						order--;
					else
						order++;
				}
				return order;
			});
			_csm.chain("stopped");
		}
	}

	/** Checks for Bumper Stickers, and marks bumpers to be cleared if any have been formed. **/
	private function smChecking(elapsed:Float)
	{
		var clearCount:Int = 0;
		function clear(x:Int, y:Int, count:Int, horizontal:Bool)
		{
			for (_ in 0...count)
			{
				if (horizontal)
					x--;
				else
					y--;
				var bumper = atGrid(_bumpers, x, y);
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
					var bumper = horizontal ? atGrid(_bumpers, x, y) : atGrid(_bumpers, y, x);
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
			curChain++;
			onMatch.dispatch(curChain, clearCount);
			_csm.chain("match");
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
				_csm.chain("nomatch");
			else
			{
				// NOTE: Game over
				onGameOver.dispatch();
				_bumpers.forEach(bumper -> bumper.gameOver());
				_csm.chain("gameover");
			}
		}
	}

	/** State machine call for clearing state. **/
	private function smClearing(elapsed:Float)
	{
		_delay -= elapsed;
		if (_delay <= 0)
		{
			for (y in 0...bHeight)
				for (x in 0...bWidth)
				{
					var bumper = atGrid(_bumpers, x, y);
					if (bumper != null && bumper.direction == Clearing)
					{
						onClear.dispatch(curChain);
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
				_bumpers.remove(bumper);
				bumper.destroy();
			}

			for (space in _spaces)
				space.reservedFor = null;
			if (_bumpers.length == 0)
			{
				// NOTE: All Clear
				_launchers.forEach(launcher -> launcher.enabled = true);
				_csm.chain("allclear");
			}
			else
			{
				FlxG.overlap(_bumpers, _spaces, bumperToSpace);
				_csm.chain("cleared");
			}
		}
	}

	/** 
		Event handler for when launchers are clicked.
		@param obj The launcher that was clicked.
	**/
	private function onClickLauncher(obj:BoardObject)
	{
		if (!Std.isOfType(obj, Launcher))
			return;
		var launcher = cast(obj, Launcher);
		if (_csm.is("initial") && launcher.state == Selected)
		{
			var bumper = new Bumper(0, 0, Blue, None);
			onLaunchBumper.dispatch(b -> bumper = b);
			bumper.onClick.add(onClickBumper);
			bumper.revive(); // just in case
			launcher.launchBumper(bumper);
			_bumpers.add(bumper);
			for (launcher in _launchers)
				launcher.enabled = false;
			// _csm.activeState = smMoving;
			_csm.chain("launch");
		}
	}

	/**
		Event handler for when bumpers are clicked. Does nothing on its own; rather, it is meant to be overridden.
		@param obj The bumper that was clicked.
	**/
	private function onClickBumper(obj:BoardObject) {};

	/**
		This function checks for overlaps between bumpers.
		@param lh One of the overlapping sprites.
		@param rh The other overlapping sprite.
	**/
	private function bumperBump(lh:FlxSprite, rh:FlxSprite)
	{
		if (!lh.alive || !rh.alive)
			return;

		var blh = spriteTo(_bumpers, lh), brh = spriteTo(_bumpers, rh);
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

		var bumper = spriteTo(_bumpers, bspr), space = spriteTo(_spaces, sspr);
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
}
