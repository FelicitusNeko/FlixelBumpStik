package boardObject.archipelago;

import components.Board;
import flixel.util.FlxColor;

class APHazardPlaceholder extends BoardObject
{
	private var _resolveColor:FlxColor;

	public function new(x:Float, y:Float, resolveColor:FlxColor, owner:Board = null)
	{
		super(x, y, owner);

		solid = false;

		base.makeGraphic(64, 64, FlxColor.fromRGBFloat(1, 0, 0, .5));
		base.solid = false;

		_resolveColor = resolveColor;
	}

	override function onAdvanceTurn():Bool
	{
		if (owner == null)
			destroy();
		else if (owner.bumperAt(boardX, boardY) != null)
		{
			var newPos = owner.getRandomSpace(true);
			if (newPos == null)
				destroy();
			else
			{
				boardX = newPos[0];
				boardY = newPos[1];
			}
		}
		else
		{
			owner.putBumperAt(boardX, boardY, new APHazardBumper(0, 0, _resolveColor, owner)).snapToPos();
			destroy();
			return true;
		}
		return false;
	}
}
