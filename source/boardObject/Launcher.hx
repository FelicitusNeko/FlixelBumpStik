package boardObject;

import components.common.CommonBoard;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import boardObject.Bumper.Direction;

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

	/** The sprite representing the arrow or symbol of this launcher. **/
	public var arrow(default, null):FlxSprite;

	/** The bumper this launcher has just launched. **/
	public var launching(default, null):Bumper = null;

	/** The X position ahead of the launcher's current position relative to the play field. **/
	public var forwardX(get, never):Int;

	/** The Y position ahead of the launcher's current position relative to the play field. **/
	public var forwardY(get, never):Int;

	/** The current state of the launcher. **/
	public var state(default, set):LState = Open;

	/** Whether this launcher is currently enabled. **/
	public var enabled(default, set):Bool = true;

	public function new(x:Float, y:Float, direction:Direction, owner:CommonBoard = null)
	{
		super(x, y, owner);

		base.loadGraphic(AssetPaths.BumperBase__png);
		base.onOver.callback = onBaseOver;
		base.onOut.callback = onBaseOut;
		base.onDown.callback = onBaseDown;
		base.onUp.callback = onBaseUp;

		arrow = new FlxSprite(0, 0);
		arrow.loadGraphic(AssetPaths.BumperSymbols__png, true, cast(width, Int), cast(height, Int));
		// arrow.blend = "multiply";
		arrow.solid = false;
		add(arrow);

		this.direction = direction;

		newFinally();
	}

	override function get_objType()
		return "launcher";

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
				color = FlxColor.GRAY;
		}
		return this.state = state;
	}

	function get_forwardX():Int
	{
		switch (direction)
		{
			case Left:
				return boardX - 1;
			case Right:
				return boardX + 1;
			default:
				return boardX;
		}
	}

	function get_forwardY():Int
	{
		switch (direction)
		{
			case Up:
				return boardY - 1;
			case Down:
				return boardY + 1;
			default:
				return boardY;
		}
	}

	function set_enabled(enabled:Bool):Bool
	{
		if (enabled)
		{
			#if mobile
			var touch = FlxG.touches.getFirst();
			var pos = touch != null ? touch.getWorldPosition() : null;
			#else
			var pos = FlxG.mouse.getWorldPosition();
			#end
			var isOver = pos != null ? overlapsPoint(pos) : false;

			if (owner != null && owner.bumperAt(forwardX, forwardY) != null)
				state = Blocked;
			else if (isOver)
				state = Hovering;
			else
				state = Open;
		}
		else
			state = Blocked;
		return this.enabled = enabled;
	}

	function onBaseDown()
	{
		#if mobile
		if (state == Hovering || state == Open)
		#else
		if (state == Hovering)
		#end
		state = Selected;
	}

	function onBaseUp()
	{
		if (state == Selected)
			onClick.dispatch(this);
	}

	function onBaseOver()
	{
		if (state == Open)
			state = Hovering;
		else if (state == SelectedNotHovering)
			state = Selected;
	}

	function onBaseOut()
	{
		if (state == Hovering)
			state = Open;
		else if (state == Selected)
			state = SelectedNotHovering;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (state == SelectedNotHovering)
		{
			#if mobile
			var touch = FlxG.touches.getFirst();
			if (touch != null && touch.justReleased)
			#else
			if (FlxG.mouse.justReleased)
			#end
			{
				state = Open;
			}
		}
	}

	/**
		Launches a given bumper onto the board.
		@param bumper The bumper to launch.
	**/
	public function launchBumper(bumper:Bumper)
	{
		launching = bumper;
		bumper.owner = owner;
		bumper.x = x;
		bumper.y = y;
		bumper.snapToPos();
		bumper.startMoving(direction);
	}
}
