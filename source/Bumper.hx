import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

enum abstract Color(FlxColor)
{
	var Blue = 0xff2244cc;
	var Green = 0xff22cc44;
	var Red = 0xffcc3333;
}

enum Direction
{
	None;
	Up;
	Right;
	Down;
	Left;
	Clearing;
	GameOver;
}

class Bumper extends FlxTypedGroup<FlxSprite>
{
	public var direction(default, set):Direction = None;
	public var launchDirection(default, set):Direction = None;
	public var activeDirection(get, never):Direction;

	public var base(default, null):FlxSprite;
	public var arrow(default, null):FlxSprite;

	public var x(get, set):Float;
	public var y(get, set):Float;
	public var velocity(get, never):FlxPoint;
	public var color(default, set):FlxColor;

	public var isMoving(get, never):Bool;
	public var boardX(get, set):Int;
	public var boardY(get, set):Int;
	public var frontX(get, never):Int;
	public var frontY(get, never):Int;

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
			base.color = arrow.color = FlxColor.RED;
		else if (this.direction == Direction.GameOver)
			base.color = arrow.color = this.color;

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

	function get_x():Float
	{
		return base.x;
	}

	function set_x(x:Float):Float
	{
		return base.x = x;
	}

	function get_y():Float
	{
		return base.y;
	}

	function set_y(y:Float):Float
	{
		return base.y = y;
	}

	function get_velocity():FlxPoint
	{
		return base.velocity;
	}

	function set_color(color:FlxColor):FlxColor
	{
		if (direction != Direction.GameOver)
			base.color = arrow.color = color;
		return this.color = color;
	}

	function get_isMoving():Bool
	{
		return Math.abs(base.velocity.x) + Math.abs(base.velocity.y) > 0
			|| Math.abs(base.acceleration.x) + Math.abs(base.acceleration.y) > 0;
	}

	function get_boardX():Int
	{
		var refX = base.x + (base.width / 2);
		return Math.floor(refX / base.width);
	}

	function set_boardX(boardX:Int):Int
	{
		base.x = boardX * base.width;
		return boardX;
	}

	function get_boardY():Int
	{
		var refY = base.y + (base.height / 2);
		return Math.floor(refY / base.height);
	}

	function set_boardY(boardY:Int):Int
	{
		base.y = boardY * base.height;
		return boardY;
	}

	function get_frontX():Int
	{
		var refX = base.x + (base.width / 2);
		switch (activeDirection)
		{
			case Right:
				refX += base.width / 2;
				if (refX % base.width == 0)
					refX--;
			case Left:
				refX -= base.width / 2;
			default:
		}

		return Math.floor(refX / base.width);
	}

	function get_frontY():Int
	{
		var refY = base.y + (base.height / 2);
		switch (activeDirection)
		{
			case Up:
				refY += base.height / 2;
				if (refY % base.height == 0)
					refY--;
			case Down:
				refY -= base.height / 2;
			default:
		}

		return Math.floor(refY / base.height);
	}

	public function new(x:Float, y:Float, color:Color, direction:Direction = Direction.None, launchDirection:Direction = Direction.None)
	{
		super();

		base = new FlxSprite(x, y);
		base.loadGraphic(AssetPaths.BumperBase__png);
		add(base);

		arrow = new FlxSprite(x, y);
		arrow.loadGraphic(AssetPaths.BumperSymbols__png, true, cast(base.width, Int), cast(base.height, Int));
		arrow.alive = false;
		add(arrow);

		// trace("Created " + base.ID + " and " + arrow.ID);

		this.color = cast(color, FlxColor);
		this.direction = direction;
		this.launchDirection = launchDirection;

		base.maxVelocity.x = base.width * 8;
		base.maxVelocity.y = base.height * 8;
	}

	public function startMoving(launched:Direction = Direction.None)
	{
		if (launched != Direction.None)
			launchDirection = launched;

		switch (activeDirection)
		{
			case Up:
				base.acceleration.y = -base.height * 2;
				if (launched != Direction.None)
					base.velocity.y = -base.maxVelocity.y / 2;
			case Right:
				base.acceleration.x = base.width * 2;
				if (launched != Direction.None)
					base.velocity.x = base.maxVelocity.x / 2;
			case Down:
				base.acceleration.y = base.height * 2;
				if (launched != Direction.None)
					base.velocity.y = base.maxVelocity.y / 2;
			case Left:
				base.acceleration.x = -base.width * 2;
				if (launched != Direction.None)
					base.velocity.x = -base.maxVelocity.x / 2;
			default:
		}
	}

	public function snapToPos()
	{
		base.velocity.x = base.velocity.y = 0;
		base.acceleration.x = base.acceleration.y = 0;
		boardX = boardX;
		boardY = boardY;
		// trace(base.x + " " + base.y);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		arrow.x = base.x;
		arrow.y = base.y;
	}
}
