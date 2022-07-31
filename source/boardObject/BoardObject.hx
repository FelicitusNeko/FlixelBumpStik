package boardObject;

import components.Board;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.ui.FlxSpriteButton;
import lime.app.Event;

/** Any of a class of object that composes a Bumper Stickers board. **/
abstract class BoardObject extends FlxSpriteGroup
{
	/** The board this bumper belongs to. **/
	public var owner(default, set):Board;

	/** The board's origin point, or (0,0) if there is no owner board. **/
	public var bOrigin(get, never):FlxPoint;

	/** The sprite button representing the base of this object. **/
	public var base(default, null):FlxSpriteButton;

	/** The adjusted X position accounting for the board's origin point. **/
	public var adjustedX(get, set):Float;

	/** The adjusted Y position accounting for the board's origin point. **/
	public var adjustedY(get, set):Float;

	/** The nearest X position to the center of the bumper relative to the play field. **/
	public var boardX(get, set):Int;

	/** The nearest Y position to the center of the bumper relative to the play field. **/
	public var boardY(get, set):Int;

	/** Event that fires when the object is clicked. **/
	public var onClick(default, null) = new Event<BoardObject->Void>();

	public function new(x:Float, y:Float, owner:Board = null)
	{
		super(x, y);
		this.owner = owner;

		base = new FlxSpriteButton(0, 0, null, onClickF);
		base.allowSwiping = false;
		add(base);
	}

	function newFinally()
	{
		setSize(width - .0002, height - .0002);
		offset.set(.0001, .0001);
	}

	function set_owner(owner:Board):Board
	{
		// if (this.owner == owner)
		// 	return owner;

		var oldOrigin = this.owner != null ? this.owner.origin : new FlxPoint(0, 0);
		var newOrigin = owner != null ? owner.origin : new FlxPoint(0, 0);

		if (!oldOrigin.equals(newOrigin))
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
		adjustedX = Math.round(boardX * width);
		return boardX;
	}

	function get_boardY():Int
	{
		var refY = adjustedY + (height / 2);
		return Math.floor(refY / height);
	}

	function set_boardY(boardY:Int):Int
	{
		adjustedY = Math.round(boardY * height);
		return boardY;
	}

	/**
		Determines whether the given sprite is located in this board object.
		@param spr The sprite for which to check
		@return Whether the sprite is contained in this board object.
	**/
	public function has(spr:FlxSprite):Bool
	{
		for (mspr in group)
			if (spr == mspr)
				return true;
		return false;
	}

	private function onClickF()
	{
		onClick.dispatch(this);
	}

	/** Called when a move has been completed. Does nothing on its own; meant to be overridden. **/
	public function onAdvanceTurn() {}
}
