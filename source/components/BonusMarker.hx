package components;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class BonusMarker extends FlxSpriteGroup
{
	public var sliceWidth(default, null):Float;

	private var _flicker = -1;

	public function new(x:Float, y:Float, qty:Int, isChain = false)
	{
		super(x, y);

		var text = new FlxText(0, 0, 0, (isChain ? "x" : "") + qty, 10);
		sliceWidth = text.x = text.height;

		var base = new FlxSprite(1, 1);
		base.makeGraphic(Math.round(text.width + (text.height * 2)), Math.round(text.height), FlxColor.TRANSPARENT);
		base.drawPolygon([
			new FlxPoint(0, base.height),
			new FlxPoint(text.height, 0),
			new FlxPoint(base.width, 0),
			new FlxPoint(base.width - text.height, base.height)
		], isChain ? FlxColor.RED : FlxColor.GREEN, {
			color: FlxColor.WHITE,
			thickness: 1
		});

		add(base);
		add(text);

		FlxTween.tween(this, {y: y - height * 2}, .75, {
			ease: FlxEase.circOut,
			onComplete: (_) ->
			{
				_flicker = 20;
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (_flicker >= 0)
		{
			visible = (--_flicker % 4 <= 1);
			if (_flicker < 0)
				kill();
		}
	}
}
