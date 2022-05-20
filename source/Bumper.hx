import flixel.FlxSprite;
import flixel.util.FlxColor;

enum abstract Color(Int)
{
	var Blue = 0x2244cc;
	var Green = 0x22cc44;
	var Red = 0xcc3333;
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

class Bumper extends FlxSprite
{
	public var direction(default, set):Direction = None;
	public var launchDirection(default, set):Direction = None;
	public var activeDirection(get, never):Direction;
	public var arrow(default, null):FlxSprite;

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

	public function new(x:Float, y:Float, color:Color, direction:Direction = Direction.None, launchDirection:Direction = Direction.None)
	{
		super(x, y);
		makeGraphic(64, 64, FlxColor.GRAY);

		arrow = new FlxSprite(x + 16, y + 8);
		arrow.makeGraphic(32, 48, FlxColor.WHITE);

		this.color = cast(color, Int);
		this.direction = direction;
		this.launchDirection = launchDirection;

		maxVelocity.x = width * 8;
		maxVelocity.y = height * 8;
	}

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

	public function snapToPos()
	{
		velocity.x = velocity.y = 0;
		acceleration.x = acceleration.y = 0;
		boardX = boardX;
		boardY = boardY;
		trace(x + " " + y);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		arrow.x = x + 16;
		arrow.y = y + 8;
	}
}
