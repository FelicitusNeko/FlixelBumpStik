package components.classic;

import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class AllClearSubstate extends FlxSubState
{
	var _amount:Int;

	var _center:FlxPoint;

	var _delay = 2.0;

	public function new(amount:Int, center:FlxPoint)
	{
		super();
		_amount = amount;
		_center = center;
	}

	override function create()
	{
		var backdrop = new FlxSprite(_center.x - 100, _center.y - 40);
		backdrop.makeGraphic(200, 80, FlxColor.TRANSPARENT);
		backdrop.drawRoundRect(0, 0, backdrop.width, backdrop.height, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});
		add(backdrop);

		var text = new FlxText(backdrop.x, backdrop.y, backdrop.width, "All Clear", 30);
		text.height = backdrop.height;
		text.alignment = CENTER;
		add(text);

		var jackpotText = new FlxBitmapText(FlxBitmapFont.fromAngelCode(AssetPaths.Diginum__png, AssetPaths.Diginum__xml));
		jackpotText.color = FlxColor.YELLOW;
		jackpotText.alignment = CENTER;
		jackpotText.autoSize = false;
		jackpotText.width = backdrop.width;
		jackpotText.text = Std.string(Math.min(_amount, 99999));
		while (jackpotText.text.length < 5)
			jackpotText.text = "z" + jackpotText.text;
		jackpotText.x = backdrop.x + (backdrop.width / 2);
		jackpotText.y = backdrop.y + 12;
		jackpotText.scale.set(.5, .5);
		add(jackpotText);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_delay -= elapsed;
		if (_delay <= 0)
			close();
	}
}
