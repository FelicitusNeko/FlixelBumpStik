package boardObject;

import flixel.FlxSprite;
import flixel.util.FlxColor;

/** The current color of the bumper, for matching purposes. **/
enum abstract Color(FlxColor)
{
	var None = 0xff000000;
	var Blue = 0xff2244cc;
	var Green = 0xff22cc44;
	var Red = 0xffcc3333;
	var Purple = 0xffa45ced;
	var Yellow = 0xfffffb23;
	var White = 0xffdddddd;
}

/** The current direction or state of the bumper, for mechanical purposes. **/
enum Direction
{
	/** The bumper is stationary, or else no direction is being provided. **/
	None;

	Up;
	Right;
	Down;
	Left;

	/** The bumper is queued to be cleared. **/
	Clearing;

	/** The game is over, and the bumper is displaying this. **/
	GameOver;
}

/** Bumpers are the basic play pieces for Bumper Stickers. **/
class Bumper extends BoardObject
{
	static final ACCELFACTOR:Float = 8;

	/** The color of this bumper. **/
	public var bColor(default, set):Color;

	/** The facing direction of this bumper. **/
	public var direction(default, set):Direction = None;

	/** The launched direction of this bumper, if any. **/
	public var launchDirection(default, set):Direction = None;

	/**
		The active direction of motion of this bumper.
		This will first resolve as `launchDirection`, then `direction`.
	**/
	public var activeDirection(get, never):Direction;

	/** The sprite representing the base of this bumper. **/
	public var base(default, null):FlxSprite;

	/** The sprite representing the arrow or symbol of this bumper. **/
	public var arrow(default, null):FlxSprite;

	/** Whether this bumper is in motion. **/
	public var isMoving(get, never):Bool;

	/** The nearest X position to the front of the bumper relative to the play field. **/
	public var frontX(get, never):Int;

	/** The nearest Y position to the front of the bumper relative to the play field. **/
	public var frontY(get, never):Int;

	/** The nearest X position to the front of the bumper relative to the play field in the previous frame. **/
	public var lfFrontX(default, null):Int;

	/** The nearest Y position to the front of the bumper relative to the play field in the previous frame. **/
	public var lfFrontY(default, null):Int;

	/** The X position ahead of the bumper's current position relative to the play field. **/
	public var forwardX(get, never):Int;

	/** The Y position ahead of the bumper's current position relative to the play field. **/
	public var forwardY(get, never):Int;

	/** Whether the front of this bumper has moved to a new board position in the last frame. **/
	public var hasShifted(get, never):Bool;

	/** Whether this bumper has just been launched. **/
	public var justLaunched(default, null):Bool = false;

	public function new(x:Float, y:Float, color:Color, direction:Direction = Direction.None, launchDirection:Direction = Direction.None, owner:Board = null)
	{
		super(x, y, owner);

		base = new FlxSprite(0, 0);
		base.loadGraphic(AssetPaths.BumperBase__png);
		add(base);

		arrow = new FlxSprite(0, 0);
		arrow.loadGraphic(AssetPaths.BumperSymbols__png, true, cast(width, Int), cast(height, Int));
		arrow.alive = false;
		add(arrow);

		this.bColor = color;
		this.direction = direction;
		this.launchDirection = launchDirection;

		lfFrontX = frontX;
		lfFrontY = frontY;

		maxVelocity.x = width * 8;
		maxVelocity.y = height * 8;
	}

	function set_bColor(bColor:Color):Color
	{
		if (direction != Direction.GameOver)
			base.color = arrow.color = cast(bColor, FlxColor);
		return this.bColor = bColor;
	}

	function set_direction(direction:Direction):Direction
	{
		switch (direction)
		{
			case Right:
				arrow.angle = 90;
			case Down:
				arrow.angle = 180;
			case Left:
				arrow.angle = 270;
			default:
				arrow.angle = 0;
		}
		switch (direction)
		{
			case None, GameOver:
				arrow.animation.frameIndex = 2;
			case Clearing:
				arrow.animation.frameIndex = 1;
			default:
				arrow.animation.frameIndex = 0;
		}

		if (direction == Direction.GameOver && this.direction != Direction.GameOver)
			color = arrow.color = FlxColor.RED;
		else if (this.direction == Direction.GameOver)
			color = arrow.color = this.color;

		return this.direction = direction;
	}

	function set_launchDirection(launchDirection:Direction):Direction
	{
		// TODO: redirect movement angle as needed (does not change the sprite)
		return this.launchDirection = launchDirection;
	}

	function get_activeDirection():Direction
	{
		if (launchDirection != Direction.None)
			return launchDirection;
		else
			return direction;
	}

	function get_isMoving():Bool
	{
		return Math.abs(velocity.x) + Math.abs(velocity.y) > 0 || Math.abs(acceleration.x) + Math.abs(acceleration.y) > 0;
	}

	function get_frontX():Int
	{
		if (!isMoving)
			return boardX;
		var refX = adjustedX + (width / 2);
		switch (activeDirection)
		{
			case Right:
				refX += width / 2;
				if (refX % width == 0)
					refX--;
			case Left:
				refX -= width / 2;
			default:
		}

		return Math.floor(refX / width);
	}

	function get_frontY():Int
	{
		if (!isMoving)
			return boardY;
		var refY = adjustedY + (height / 2);
		switch (activeDirection)
		{
			case Down:
				refY += height / 2;
				if (refY % height == 0)
					refY--;
			case Up:
				refY -= height / 2;
			default:
		}

		return Math.floor(refY / height);
	}

	function get_forwardX():Int
	{
		switch (activeDirection)
		{
			case Left:
				return frontX - 1;
			case Right:
				return frontX + 1;
			default:
				return frontX;
		}
	}

	function get_forwardY():Int
	{
		switch (activeDirection)
		{
			case Up:
				return frontY - 1;
			case Down:
				return frontY + 1;
			default:
				return frontY;
		}
	}

	function get_hasShifted():Bool
	{
		return lfFrontX != frontX || lfFrontY != frontY;
	}

	/**
		Starts this bumper moving in its set direction, if any.
		@param launched Optional. If provided, the bumper will be launched in a temporary direction,
										starting at half its maximum velocity.
	**/
	public function startMoving(launched:Direction = Direction.None)
	{
		if (launched != Direction.None)
		{
			justLaunched = true;
			launchDirection = launched;
		}

		acceleration.x = acceleration.y = velocity.x = velocity.y = 0;

		switch (activeDirection)
		{
			case Up:
				acceleration.y = -height * ACCELFACTOR;
				if (launched != Direction.None)
					velocity.y = -maxVelocity.y / 2;
			case Right:
				acceleration.x = width * ACCELFACTOR;
				if (launched != Direction.None)
					velocity.x = maxVelocity.x / 2;
			case Down:
				acceleration.y = height * ACCELFACTOR;
				if (launched != Direction.None)
					velocity.y = maxVelocity.y / 2;
			case Left:
				acceleration.x = -width * ACCELFACTOR;
				if (launched != Direction.None)
					velocity.x = -maxVelocity.x / 2;
			default:
		}
	}

	/**
		Snaps the bumper to the nearest board X/Y location.
	**/
	public function snapToPos()
	{
		velocity.x = velocity.y = 0;
		acceleration.x = acceleration.y = 0;
		boardX = boardX;
		boardY = boardY;
		launchDirection = Direction.None;
	}

	/**
		Mark this bumper to be cleared.
		@return Whether the bumper has been marked for clearing.
			If the bumper has already been marked, it will not be marked again.
	**/
	public function markForClear()
	{
		if (direction == Clearing)
			return false;
		// TODO: clear animation
		direction = Clearing;
		return true;
	}

	override function update(elapsed:Float)
	{
		lfFrontX = frontX;
		lfFrontY = frontY;
		super.update(elapsed);
		if (justLaunched)
			justLaunched = false;
	}
}
