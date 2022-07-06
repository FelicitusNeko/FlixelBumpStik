package boardObject;

import boardObject.Bumper;
import components.Board;
import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
	Board spaces may seem like a background detail, but they do assist in preventing mid-space collisions
	that would result in two bumpers occupying the same space at the end of movement.
**/
class BoardSpace extends BoardObject
{
	/** The bumper for which this space is reserved. This is to prevent mid-space collision. **/
	public var reservedFor:Bumper = null;

	public function new(x:Float, y:Float, owner:Board)
	{
		super(x, y, owner);

		base.makeGraphic(64, 64, FlxColor.GRAY);
		newFinally();
	}
}
