import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
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

	/** The nearest X position to the center of the bumper relative to the play field. **/
	public var boardX(get, set):Int;

	/** The nearest Y position to the center of the bumper relative to the play field. **/
	public var boardY(get, set):Int;

	/** The nearest X position to the front of the bumper relative to the play field. **/
	public var frontX(get, never):Int;

	/** The nearest Y position to the front of the bumper relative to the play field. **/
	public var frontY(get, never):Int;

	/** The nearest X position to the front of the bumper relative to the play field in the previous frame. **/
	public var lfFrontX(default, null):Int;

	/** The nearest Y position to the front of the bumper relative to the play field in the previous frame. **/
	public var lfFrontY(default, null):Int;

	/** Whether the front of this bumper has moved to a new board position in the last frame. **/
	public var hasShifted(get, never):Bool;

	public function new(x:Float, y:Float, color:Color, direction:Direction = Direction.None, launchDirection:Direction = Direction.None)
	{
		super(x, y);

		base = new FlxSprite(x, y);
		base.loadGraphic(AssetPaths.BumperBase__png);
		add(base);

		arrow = new FlxSprite(x, y);
		arrow.loadGraphic(AssetPaths.BumperSymbols__png, true, cast(width, Int), cast(height, Int));
		arrow.alive = false;
		add(arrow);

		// trace("Created " + ID + " with " + base.ID + " and " + arrow.ID);

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
		// TODO: change sprite based on direction
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

	function get_boardX():Int
	{
		var refX = x + (width / 2);
		return Math.floor(refX / width);
	}

	function set_boardX(boardX:Int):Int
	{
		x = boardX * width;
		return boardX;
	}

	function get_boardY():Int
	{
		var refY = y + (height / 2);
		return Math.floor(refY / height);
	}

	function set_boardY(boardY:Int):Int
	{
		y = boardY * height;
		return boardY;
	}

	function get_frontX():Int
	{
		if (!isMoving)
			return boardX;
		var refX = x + (width / 2);
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
		var refY = y + (height / 2);
		switch (activeDirection)
		{
			case Up:
				refY += height / 2;
				if (refY % height == 0)
					refY--;
			case Down:
				refY -= height / 2;
			default:
		}

		return Math.floor(refY / height);
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
			launchDirection = launched;

		switch (activeDirection)
		{
			case Up:
				acceleration.y = -height * 2;
				if (launched != Direction.None)
					velocity.y = -maxVelocity.y / 2;
			case Right:
				acceleration.x = width * 2;
				if (launched != Direction.None)
					velocity.x = maxVelocity.x / 2;
			case Down:
				acceleration.y = height * 2;
				if (launched != Direction.None)
					velocity.y = maxVelocity.y / 2;
			case Left:
				acceleration.x = -width * 2;
				if (launched != Direction.None)
					velocity.x = -maxVelocity.x / 2;
			default:
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

	public function isAt(x:Int, y:Int):Bool
	{
		// var rX = x * width, rY = y * height;
		// if (rX < this.x || rX > this.x + width)
		// 	return false;
		// if (rY < this.y || rY > this.y + height)
		// 	return false;
		// return true;
		return !(new FlxRect(x * width, y * width, width, height).intersection(new FlxRect(this.x, this.y, width, height)).isEmpty);
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
		// trace(x + " " + y);
	}

	override function update(elapsed:Float)
	{
		lfFrontX = frontX;
		lfFrontY = frontY;
		super.update(elapsed);
		forEach(spr ->
		{
			spr.x = x;
			spr.y = y;
		});
	}
}
