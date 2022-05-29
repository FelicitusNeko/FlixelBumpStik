import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
	Board spaces may seem like a background detail, but they do assist in preventing mid-space collisions
	that would result in two bumpers occupying the same space at the end of movement.
**/
class BoardSpace extends FlxSprite
{
	/** The bumper for which this space is reserved. This is to prevent mid-space collision. **/
	public var reservedFor:Bumper = null;

	/** This space's grid-based X position. **/
	public var boardX(get, never):Int;

	/** This space's grid-based Y position. **/
	public var boardY(get, never):Int;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		makeGraphic(64, 64, FlxColor.GRAY);
	}

	function get_boardX():Int
	{
		var refX = x + (width / 2);
		return Math.floor(refX / width);
	}

	function get_boardY():Int
	{
		var refY = y + (height / 2);
		return Math.floor(refY / height);
	}
}
