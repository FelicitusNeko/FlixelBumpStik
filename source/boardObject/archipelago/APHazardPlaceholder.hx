package boardObject.archipelago;

import boardObject.Bumper.Direction;

class APHazardPlaceholder extends BoardObject
{
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
			owner.makeBumperAt(boardX, boardY, null, Direction.None);
			return true;
		}
		return false;
	}
}
