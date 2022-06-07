import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

/** The current color of the bumper, for matching purposes. **/
enum abstract Color(FlxColor)
{
	var Blue = 0xff2244cc;
	var Green = 0xff22cc44;
	var Red = 0xffcc3333;
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
class Bumper extends FlxSpriteGroup
{
	/** The board this bumper belongs to. **/
	public var owner(default, set):Board;

	/** The board's origin point, or (0,0) if there is no owner board. **/
	public var bOrigin(get, never):FlxPoint;

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

	/** The adjusted X position accounting for the board's origin point. **/
	public var adjustedX(get, set):Float;

	/** The adjusted Y position accounting for the board's origin point. **/
	public var adjustedY(get, set):Float;

	/** The nearest X position to the center of the bumper relative to the play field. **/
	public var boardX(get, set):Int;

	/** The nearest Y position to the center of the bumper relative to the play field. **/
	public var boardY(get, set):Int;

	/** The nearest X position to the front of the bumper relative to the play field. **/
	public var frontX(get, never):Int;

	/** The nearest Y position to the front of the bumper relative to the play field. **/
	public var frontY(get, never):Int;

	/** The X position ahead of the bumper's current position relative to the play field. **/
	public var forwardX(get, never):Int;

	/** The Y position ahead of the bumper's current position relative to the play field. **/
	public var forwardY(get, never):Int;

	/** The nearest X position to the front of the bumper relative to the play field in the previous frame. **/
	public var lfFrontX(default, null):Int;

	/** The nearest Y position to the front of the bumper relative to the play field in the previous frame. **/
	public var lfFrontY(default, null):Int;

	/** Whether the front of this bumper has moved to a new board position in the last frame. **/
	public var hasShifted(get, never):Bool;

	/** Whether this bumper has just been launched. **/
	public var justLaunched(default, null):Bool = false;

	public function new(x:Float, y:Float, color:Color, direction:Direction = Direction.None, launchDirection:Direction = Direction.None, owner:Board = null)
	{
		super(x, y);

		base = new FlxSprite(0, 0);
		base.loadGraphic(AssetPaths.BumperBase__png);
		add(base);

		arrow = new FlxSprite(0, 0);
		arrow.loadGraphic(AssetPaths.BumperSymbols__png, true, cast(width, Int), cast(height, Int));
		arrow.alive = false;
		add(arrow);

		// trace("Created " + ID + " with " + base.ID + " and " + arrow.ID);

		this.bColor = color;
		this.direction = direction;
		this.launchDirection = launchDirection;
		this.owner = owner;

		lfFrontX = frontX;
		lfFrontY = frontY;

		maxVelocity.x = width * 8;
		maxVelocity.y = height * 8;
	}

	function set_owner(owner:Board):Board
	{
		var oldOrigin = this.owner != null ? this.owner.origin : new FlxPoint(0, 0);
		var newOrigin = owner != null ? owner.origin : new FlxPoint(0, 0);

		if (oldOrigin.equals(newOrigin))
		{
			var deltaOrigin = newOrigin.subtractPoint(oldOrigin);

			x += deltaOrigin.x;
			y += deltaOrigin.y;
		}

		return this.owner = owner;
	}

	function get_bOrigin():FlxPoint
	{
		return owner != null ? owner.origin : new FlxPoint(0, 0);
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

	function get_adjustedX():Float
	{
		return x - bOrigin.x;
	}

	function set_adjustedX(adjustedX:Float):Float
	{
		x = adjustedX + bOrigin.x;
		return adjustedX;
	}

	function get_adjustedY():Float
	{
		return y - bOrigin.y;
	}

	function set_adjustedY(adjustedY:Float):Float
	{
		y = adjustedY + bOrigin.y;
		return adjustedY;
	}

	function get_boardX():Int
	{
		var refX = adjustedX + (width / 2);
		return Math.floor(refX / width);
	}

	function set_boardX(boardX:Int):Int
	{
		adjustedX = boardX * width;
		return boardX;
	}

	function get_boardY():Int
	{
		var refY = adjustedY + (height / 2);
		return Math.floor(refY / height);
	}

	function set_boardY(boardY:Int):Int
	{
		adjustedY = boardY * height;
		return boardY;
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
			// trace("Bumper " + ID + " being launched " + launched);
			justLaunched = true;
			launchDirection = launched;
		}
		else
			// trace("Bumper " + ID + " starting movement");

			acceleration.x = acceleration.y = velocity.x = velocity.y = 0;

		switch (activeDirection)
		{
			case Up:
				// trace("Bumper " + ID + " moving up");
				acceleration.y = -height * 4;
				if (launched != Direction.None)
					velocity.y = -maxVelocity.y / 2;
			case Right:
				// trace("Bumper " + ID + " moving right");
				acceleration.x = width * 4;
				if (launched != Direction.None)
					velocity.x = maxVelocity.x / 2;
			case Down:
				// trace("Bumper " + ID + " moving down");
				acceleration.y = height * 4;
				if (launched != Direction.None)
					velocity.y = maxVelocity.y / 2;
			case Left:
				// trace("Bumper " + ID + " moving left");
				acceleration.x = -width * 4;
				if (launched != Direction.None)
					velocity.x = -maxVelocity.x / 2;
			default:
				// trace("Bumper " + ID + " has no direction of motion");
		}
	}

	/**
		Determines whether the given sprite is located in this group.
		@param spr The sprite for which to check
		@return Whether the sprite is contained in this sprite group.
	**/
	public function has(spr:FlxSprite):Bool
	{
		for (mspr in group)
			if (spr == mspr)
				return true;
		return false;
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
		// trace("Bumper " + ID + " Snap: " + x, y);
	}

	override function update(elapsed:Float)
	{
		lfFrontX = frontX;
		lfFrontY = frontY;
		super.update(elapsed);
		// if (hasShifted)
		// 	trace("Bumper going from " + lfFrontX, lfFrontY + " to " + frontX, frontY);
		if (justLaunched)
			justLaunched = false;
	}
}
