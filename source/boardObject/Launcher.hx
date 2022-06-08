package boardObject;

import boardObject.Bumper.Direction;
import flixel.FlxSprite;
import flixel.util.FlxColor;

enum LState
{
	Open;
	Hovering;
	Selected;
	SelectedNotHovering;
	Blocked;
}

/** Launchers are responsible for launching bumpers onto the board. **/
class Launcher extends BoardObject
{
	/** The facing (and launching) direction of this launcher. **/
	public var direction(default, set):Direction;

	/** The sprite representing the base of this launcher. **/
	public var base(default, null):FlxSprite;

	/** The sprite representing the arrow or symbol of this launcher. **/
	public var arrow(default, null):FlxSprite;

	/** The bumper this launcher has just launched. **/
	public var launching(default, null):Bumper = null;

	/** The current state of the launcher. **/
	public var state(default, set):LState = Open;

	public function new(x:Float, y:Float, direction:Direction, owner:Board = null)
	{
		super(x, y, owner);

		base = new FlxSprite(0, 0);
		base.loadGraphic(AssetPaths.BumperBase__png);
		add(base);

		arrow = new FlxSprite(0, 0);
		arrow.loadGraphic(AssetPaths.BumperSymbols__png, true, cast(width, Int), cast(height, Int));
		arrow.alive = false;
		add(arrow);

		this.direction = direction;
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
		return this.direction = direction;
	}

	function set_state(state:LState):LState
	{
		switch (state)
		{
			case Open:
				color = FlxColor.WHITE;
			case Hovering:
				color = FlxColor.fromRGB(225, 225, 225);
			case Selected:
				color = FlxColor.BLUE;
			case SelectedNotHovering:
				color = FlxColor.CYAN;
			case Blocked:
				color = FlxColor.RED;
		}
		return this.state = state;
	}

	/**
		Launches a given bumper onto the board.
		@param bumper The bumper to launch.
	**/
	public function launchBumper(bumper:Bumper)
	{
		// trace("Bumper " + bumper.ID + " launching from launcher " + ID);
		launching = bumper;
		bumper.owner = owner;
		bumper.x = x;
		bumper.y = y;
		bumper.snapToPos();
		bumper.startMoving(direction);
	}
}
