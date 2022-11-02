package boardObject.archipelago;

import components.Board;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

using flixel.tweens.FlxTween;

class APHazardBumper extends Bumper
{
	private var _resolveColor:FlxColor;

	private var _flashCount:Float = 0;

	private var _turnsToNormal:Int;

	public function new(x:Float, y:Float, resolveColor:FlxColor, ?owner:Board, turnsToNormal = 5)
	{
		super(x, y, null, None, None, owner);
		_turnsToNormal = turnsToNormal;

		addFlair("hazard", new FlxSprite(0, 0).loadGraphic(AssetPaths.HazardFlair__png));

		_resolveColor = resolveColor;
	}

	override function get_objType()
		return "hazardBumper";

	override function gameOver()
	{
		immovable = false;
		super.gameOver();
	}

	override function onAdvanceTurn():Bool
	{
		if (_turnsToNormal > 0)
		{
			if (--_turnsToNormal <= 0)
			{
				var hazardFlair = _flairList["hazard"];
				hazardFlair.tween({alpha: 0, "scale.x": 1.25, "scale.y": 1.25}, .5, {
					ease: FlxEase.circOut,
					onComplete: (_) ->
					{
						remove(hazardFlair);
						add(_flairList["hazard"] = new FlxSprite(0, 0)).makeGraphic(64, 64, FlxColor.TRANSPARENT);
						hazardFlair.destroy();
					}
				});
				bColor = _resolveColor;
				return true;
			}
		}

		return false;
	}

	override function update(elapsed:Float)
	{
		if (_turnsToNormal == 1)
		{
			_flashCount += elapsed;
			while (_flashCount >= .5)
			{
				_flashCount -= .5;
				arrow.color = (arrow.color == _resolveColor) ? base.color : _resolveColor;
			}
		}
		super.update(elapsed);
	}
}
