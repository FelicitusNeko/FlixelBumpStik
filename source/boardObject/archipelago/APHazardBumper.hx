package boardObject.archipelago;

import components.Board;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class APHazardBumper extends Bumper
{
	private var _resolveColor:FlxColor;

	public function new(x:Float, y:Float, resolveColor:FlxColor, ?owner:Board, turnsToNormal = 5)
	{
		super(x, y, null, None, None, owner);
		health = turnsToNormal;

		addFlair("hazard", new FlxSprite(0, 0).loadGraphic(AssetPaths.HazardFlair__png));

		_resolveColor = resolveColor;
	}

	override function onAdvanceTurn():Bool
	{
		if (health > 0)
		{
			if (--health <= 0)
			{
				_flairList["hazard"].color.alpha = 128;
				color = _resolveColor;
				return true;
			}
		}

		return false;
	}
}
