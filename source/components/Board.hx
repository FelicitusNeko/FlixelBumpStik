package components;

import haxe.DynamicAccess;
import haxe.Exception;
import haxe.Timer;
import boardObject.BoardObject;
import boardObject.BoardSpace;
import boardObject.Bumper;
import boardObject.Launcher;
import boardObject.archipelago.APHazardBumper;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
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

	/** The collection of obstacles. **/
	private var _obstacles = new FlxTypedGroup<BoardObject>();

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

	/** When Game Over hits, as a preventative measure, the game over sequence will be forced to progress after five seconds. **/
	private var _forceGameOver = false;

	/** If this is true, `onAdvanceTurn` will not be called. **/
	private var _dontAdvanceTurn = false;

	private var _frames = 0;

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
		@param bumpers The bumpers to be cleared.
	**/
	public var onMatch(default, null) = new Event<(Int, Int, Array<Bumper>) -> Void>();

	/**
		Event that fires when a bumper clears.
		@param chain The chain step for this overall match.
	**/
	public var onClear(default, null) = new Event<(Int, Bumper) -> Void>();

	/** Event that fires when the game is over. **/
	public var onGameOver(default, null) = new Event<Bool->Void>();

	public function new(x:Float = 0, y:Float = 0, bWidth = 5, bHeight = 5)
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
		add(_obstacles);
		add(_bumpers);
		add(_launchers);

		_csm = new CSM(smIdle);
		_csm.addState("lmoving", smMoving);
		_csm.addState("moving", smMoving);
		_csm.addState("checking", smChecking);
		_csm.addState("clearing", smClearing);
		_csm.addState("gameoverwait", smGameOverWait);
		_csm.addState("gameover", null);

		_csm.set("initial", "launch", "lmoving");
		_csm.set("initial", "sdlaunch", "moving");
		_csm.set("lmoving", "stopped", "moving");
		_csm.set("moving", "stopped", "checking");
		_csm.set("checking", "match", "clearing");
		_csm.set("checking", "nomatch", "initial");
		_csm.set("checking", "gameover", "gameoverwait");
		_csm.set("clearing", "cleared", "moving");
		_csm.set("clearing", "allclear", "initial");
		_csm.set("gameoverwait", "goanimdone", "gameover");

		for (launcher in _launchers)
			launcher.onClick.add(onClickLauncher);

		this.bWidth = bWidth;
		this.bHeight = bHeight;

		// setupTest(12);
	}

	inline function get_tWidth()
		return (bWidth + 2) * sWidth;

	inline function get_tHeight()
		return (bHeight + 2) * sHeight;

	inline function get_center()
		return new FlxPoint(bWidth * sWidth / 2, bHeight * sHeight / 2).addPoint(origin);

	inline function get_bCount()
		return _bumpers.countLiving();

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
				makeBumperAt(4, 3, Color.Green);
				makeBumperAt(1, 3, Color.Red, Direction.Right);
			case 1: // Head-on collision test ✔️
				makeBumperAt(0, 1, Color.Red, Direction.Right);
				makeBumperAt(4, 1, Color.Blue, Direction.Left);
			case 2: // Cross-collision test #1 - both shifting on same frame ✔️?
				makeBumperAt(0, 1, Color.Red, Direction.Right);
				makeBumperAt(2, 4, Color.Blue, Direction.Up);
			case 3: // Cross-collision test #2 - shifting on different frame ✔️
				makeBumperAt(0, 1, Color.Red, Direction.Right);
				var halfBumper = makeBumperAt(2, 4, Color.Blue, Direction.Up);
				halfBumper.y -= halfBumper.height / 2;
			case 4: // Launch test ✔️
				var lbumper = makeBumperAt(-40, -40, Color.Blue, Direction.Right);
				_launchers.getFirstAlive().launchBumper(lbumper);
				autoLaunch = false;
			case 5: // Driveby test #1 - horizontal ✔️
				makeBumperAt(0, 1, Color.Blue, Direction.Right);
				makeBumperAt(4, 2, Color.Red, Direction.Left);
			case 6: // Driveby test #2 - vertical ✔️
				makeBumperAt(1, 0, Color.Blue, Direction.Down);
				makeBumperAt(2, 4, Color.Red, Direction.Up);
			case 7: // Match test #1 - vertical ✔️
				makeBumperAt(4, 0, Color.Green, None);
				makeBumperAt(4, 1, Color.Blue, None);
				makeBumperAt(0, 2, Color.Blue, Right);
				makeBumperAt(4, 3, Color.Blue, None);
				makeBumperAt(4, 4, Color.Red, None);
			case 8: // Match test #2 - horizontal ✔️
				makeBumperAt(0, 4, Color.Green, None);
				makeBumperAt(1, 4, Color.Blue, None);
				makeBumperAt(2, 0, Color.Blue, Down);
				makeBumperAt(3, 4, Color.Blue, None);
				makeBumperAt(4, 4, Color.Red, None);
			case 9: // Corner collision ✔️
				makeBumperAt(2, 4, Color.Blue, Right);
				makeBumperAt(4, 4, Color.Blue, Right);
				makeBumperAt(2, 0, Color.Green, Down);
			case 10: // Chain scoring (×3) ✔️
				makeBumperAt(2, 2, Color.Blue, Down);
				makeBumperAt(2, 3, Color.Blue, Up);
				makeBumperAt(0, 2, Color.Green, Left);
				makeBumperAt(1, 2, Color.Green, Left);
				makeBumperAt(3, 2, Color.Green, Left);
				makeBumperAt(0, 0, Color.Red, Up);
				makeBumperAt(0, 1, Color.Red, Up);
				makeBumperAt(0, 3, Color.Red, Up);
				var launcher = atPoint(_launchers, new FlxPoint(origin.x, origin.y).add(sWidth * 2.5, sHeight * 5.5));
				if (launcher != null)
					launcher.launchBumper(new Bumper(0, 0, Color.Blue, Up));
				autoLaunch = false;
			case 11: // Rear-end collision test ✔️
				// Two bumpers moving in the same direction at the same speed which start adjacent should remain adjacent throughout the move
				makeBumperAt(4, 0, Color.Blue, Down);
				makeBumperAt(4, 1, Color.Blue, Down);
				makeBumperAt(4, 2, Color.Red, Right);
				makeBumperAt(4, 3, Color.Red, Right);
				makeBumperAt(4, 4, Color.Red, Right);
				_csm.currentState = "moving";
			case 12: // Cornering collision race-condition test ½✔️
				// Confirmed and replicated
				// A bumper attempting to enter a space that another bumper has just left is liable to cause the bumper entering to stop incorrectly
				// Partially fixed; it still stops, but at least it keeps going afterward
				makeBumperAt(1, 2, Blue, Left);
				makeBumperAt(1, 0, Red, Down);
				_csm.currentState = "moving";
			case 13: // Same-direction resting overlap test ✔️
				// Confirmed and replicated
				// It is possible for bumpers moving in the same direction to end up overlapping each other
				makeBumperAt(3, 2, Blue, Left);
				makeBumperAt(1, 2, Green, Right);
				makeBumperAt(0, 2, Red, Right);
				// _csm.currentState = "moving";
		}
		// if (autoLaunch)
		// 	_bumpers.forEachAlive(bumper ->
		// 	{
		// 		if (bumper.direction != Direction.None)
		// 			bumper.startMoving(bumper.direction);
		// 	});

		// _csm.chain("launch");
	}

	/**
		Creates a new bumper on the bumper layer and puts it at the given grid coordinates.
		@param x The horizontal board grid coordinate.
		@param y The vertical board grid coordinate.
		@param color The color of the bumper. May be `null` for an unmatchable colorless bumper.
		@param dir Optional. The direction of the bumper. Defaults to `Direction.None`.
		@return The new bumper.
	**/
	public function makeBumperAt(x:Int, y:Int, color:Null<FlxColor>, dir:Direction = Direction.None)
	{
		var bumper = new Bumper(x * sWidth, y * sHeight, color, dir, None, this);
		bumper.onClick.add(onClickBumper);
		_bumpers.add(bumper);
		return bumper;
	}

	/**
		Places an existing bumper on the bumper layer and puts it at the given grid coordinates.
		@param x The horizontal board grid coordinate.
		@param y The vertical board grid coordinate.
		@param bumper The bumper to place.
		@return The bumper.
	**/
	public function putBumperAt(x:Int, y:Int, bumper:Bumper)
	{
		bumper.owner = this;
		bumper.boardX = x;
		bumper.boardY = y;
		bumper.onClick.add(onClickBumper);
		_bumpers.add(bumper);
		return bumper;
	}

	/**
		Places a board object on the obstacle layer at the given grid coordinates.
		@param x The horizontal board grid coordinate.
		@param y The vertical board grid coordinate.
		@param obstacle The obstacle to place.
		@return The obstacle.
	**/
	public function putObstacleAt(x:Int, y:Int, obstacle:BoardObject)
	{
		obstacle.owner = this;
		obstacle.boardX = x;
		obstacle.boardY = y;
		_obstacles.add(obstacle);
		return obstacle;
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
		return atGrid(_bumpers, x, y);

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
		Get a random X/Y position on the board.
		@param shouldBeEmpty Optional. Whether the returned position should be empty. If omitted or `null`, no check will be made.
		@return An array with two elements indicating the X and Y coordinates, or `null` if no suitable position was found.
	**/
	public function getRandomSpace(?shouldBeEmpty:Bool)
	{
		var rng = new FlxRandom();
		var startX = rng.int(0, bWidth - 1), startY = rng.int(0, bHeight - 1);
		if (shouldBeEmpty == null)
			return [startX, startY];

		for (deltaY in 0...bHeight)
		{
			var curY = (startY + deltaY) % bHeight;
			for (deltaX in 0...bWidth)
			{
				var curX = (startX + deltaX) % bWidth;
				var bumper = bumperAt(curX, curY);
				if ((bumper == null) == shouldBeEmpty)
					return [curX, curY];
			}
		}

		return null;
	}

	public function getRandomBumper()
	{
		if (bCount == 0)
			return null;
		return cast(_bumpers.getRandom(), Bumper);
	}

	/**
		Updates all member objects and runs the state machine.
		@param elapsed The number of seconds passed since the last frame.
	**/
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_csm.update(elapsed);
		_frames++;
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
		var isSomethingMoving = false;
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

		FlxG.overlap(_bumpers, _bumpers, bumperBump);
		FlxG.overlap(_bumpers, _spaces, bumperToSpace);

		if (!isSomethingMoving)
			for (bumper in _bumpers)
				if (isSomethingMoving = bumper.isMoving)
					break;
		if (!isSomethingMoving)
			for (bumper in _bumpers)
			{
				var fpX = bumper.forwardX, fpY = bumper.forwardY;
				if (fpX < 0 || fpY < 0 || fpX >= bWidth || fpY >= bHeight)
					continue;
				if (atGrid(_bumpers, fpX, fpY) != null)
					continue;
				isSomethingMoving = true;
				break;
			}
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
		var clearBumpers:Array<Bumper> = [];
		// var clearCount:Int = 0;

		/** Marks bumpers to be cleared. **/
		function clear(x:Int, y:Int, count:Int, horizontal:Bool)
		{
			for (_ in 0...count)
			{
				if (horizontal)
					x--;
				else
					y--;
				var bumper = atGrid(_bumpers, x, y);
				if (bumper != null && bumper.markForClear() && !clearBumpers.contains(bumper))
					clearBumpers.push(bumper);
			}
		}

		/** Checks for Bumper Stickers in a given direction. **/
		function check(horizontal:Bool)
		{
			for (y in 0...(horizontal ? bHeight : bWidth))
			{
				var streakColor:Null<FlxColor> = null, streakLength:Int = 0;
				for (x in 0...(horizontal ? bWidth : bHeight))
				{
					var bumper = horizontal ? atGrid(_bumpers, x, y) : atGrid(_bumpers, y, x);
					if (bumper != null && bumper.bColor == streakColor && streakColor != null)
						streakLength++;
					else
					{
						if (streakLength >= 3)
							horizontal ? clear(x, y, streakLength, horizontal) : clear(y, x, streakLength, horizontal);
						streakColor = bumper != null ? bumper.bColor : null;
						streakLength = streakColor == null ? 0 : 1;
					}
				}
				if (streakLength >= 3)
					horizontal ? clear(bWidth, y, streakLength, horizontal) : clear(y, bHeight, streakLength, horizontal);
			}
		}

		for (horizontal in [true, false])
			check(horizontal);

		if (clearBumpers.length > 0)
		{
			_delay = .5;
			curChain++;
			onMatch.dispatch(curChain, clearBumpers.length, clearBumpers);
			_csm.chain("match");

			if (curChain > 1 || clearBumpers.length > 3)
			{
				var firstClearBumper:Bumper = null;
				for (y in 0...bHeight)
				{
					for (x in 0...bWidth)
					{
						var bumper = atGrid(_bumpers, x, y, false);
						if (bumper != null && bumper.direction == Clearing)
						{
							firstClearBumper = bumper;
							break;
						}
					}
					if (firstClearBumper != null)
						break;
				}
				if (firstClearBumper != null)
				{
					var putx = firstClearBumper.x - (firstClearBumper.width / 3);
					if (clearBumpers.length > 3)
					{
						var comboMarker = new BonusMarker(putx, firstClearBumper.y, clearBumpers.length);
						add(comboMarker);
						putx += comboMarker.height * 1.6;
					}
					if (curChain > 1)
						add(new BonusMarker(putx, firstClearBumper.y, curChain, true));
				}
			}
		}
		else
		{
			var recheck = false;
			if (_dontAdvanceTurn)
				_dontAdvanceTurn = false;
			else
			{
				_bumpers.forEachAlive(bumper -> recheck = recheck || bumper.onAdvanceTurn());
				_obstacles.forEachAlive(obstacle -> recheck = recheck || obstacle.onAdvanceTurn());
			}
			if (!recheck)
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
					Timer.delay(() -> if (_csm.is("gameoverwait")) _forceGameOver = true, 5000);
					onGameOver.dispatch(false);
					_bumpers.forEach(bumper -> bumper.gameOver());
					_csm.chain("gameover");
				}
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
						onClear.dispatch(curChain, bumper);
						bumper.kill();
						_delay += .15;
						return;
					}
				}

			_delay = 0;

			var deadBuffer:Array<Bumper> = [];
			_bumpers.forEachDead(bumper -> deadBuffer.push(bumper));
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

	/** State machine call for waiting for the Game Over animation to finish. **/
	private function smGameOverWait(_:Float)
	{
		if (_bumpers.getFirstExisting() == null || _forceGameOver)
		{
			onGameOver.dispatch(true);
			_csm.chain("goanimdone");
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
			var bumper = new Bumper(0, 0, Color.Blue, None);
			onLaunchBumper.dispatch(b -> bumper = b);
			bumper.onClick.add(onClickBumper);
			bumper.revive(); // just in case
			launcher.launchBumper(bumper);
			_bumpers.add(bumper);
			for (launcher in _launchers)
				launcher.enabled = false;
			// _csm.activeState = smMoving;
			_csm.chain(bumper.direction == bumper.launchDirection ? "sdlaunch" : "launch");
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

		if (blh.activeDirection == brh.activeDirection)
		{
			if (blh.isMoving && brh.isMoving)
			{
				var buf = new FlxPoint().copyFrom(blh.velocity);
				blh.velocity.copyFrom(brh.velocity);
				brh.velocity.copyFrom(buf);
			}
			else
			{
				blh.snapToPos();
				brh.snapToPos();
			}
		}
		else if (blh.hasShifted && brh.hasShifted)
		{
			if (blh.frontX == brh.lfFrontX && blh.frontY == brh.lfFrontY)
			{
				// trace('#${_frames} - Bumper at ${blh.frontX}, ${blh.frontY} snapped at pos 2 blh');
				blh.snapToPos();
			}
			else
			{
				// trace('#${_frames} - Bumper at ${brh.frontX}, ${brh.frontY} snapped at pos 2 brh');
				brh.snapToPos();
			}
		}
		else
			for (bumper in [blh, brh])
				if (bumper.hasShifted)
				{
					// trace('#${_frames} - Bumper at ${bumper.frontX}, ${bumper.frontY} snapped at pos 3');
					bumper.snapToPos();
				}
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

	public function serialize()
	{
		var retval:DynamicAccess<Dynamic> = {};

		retval["width"] = bWidth;
		retval["height"] = bHeight;
		retval["bumpers"] = [];
		_bumpers.forEachAlive(b ->
		{
			retval["bumpers"].push(b.serialize());
		});

		return retval;
	}

	public function deserialize(data:DynamicAccess<Dynamic>)
	{
		var bumpersData:Array<DynamicAccess<Dynamic>> = data["bumpers"];
		for (bumperData in bumpersData)
		{
			var bumper:Bumper = switch (bumperData["type"])
			{
				case "bumper": Bumper.fromSaved(bumperData);
				case "hazardBumper": APHazardBumper.fromSaved(bumperData);
				case x: throw new Exception('Unknown bumper type $x');
			}
			putBumperAt(bumperData["boardX"], bumperData["boardY"], bumper);
		}
	}
}
