package boardObject.archipelago;

import components.Board;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import haxe.DynamicAccess;

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

		addFlair("activeHazard");

		_resolveColor = resolveColor;
	}

	override function get_objType()
		return _turnsToNormal == 0 ? "bumper" : "hazardBumper";

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
						removeFlair("activeHazard");
						addFlair("hazard");
						// remove(hazardFlair);
						// add(_flairList["hazard"] = new FlxSprite(0, 0)).makeGraphic(64, 64, FlxColor.TRANSPARENT);
						// hazardFlair.destroy();
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

	public override function serialize():DynamicAccess<Dynamic>
	{
		var retval = super.serialize();

		if (_turnsToNormal > 0)
		{
			retval.remove("direction");
			retval.remove("bColor");
			retval["turnsToNormal"] = _turnsToNormal;
			retval["resolveColor"] = _resolveColor;
		}

		return retval;
	}

	// public override function deserialize(data:DynamicAccess<Dynamic>) {
	// 	super.deserialize(data);
	//	// Nothing else to do right now (other vars are initialised via the constructor)
	// }

	public static function fromSaved(data:DynamicAccess<Dynamic>){
		var bumper = new APHazardBumper(0, 0, data["resolveColor"], null, data["turnsToNormal"]);
		bumper.deserialize(data);
		return bumper;
	}
}
