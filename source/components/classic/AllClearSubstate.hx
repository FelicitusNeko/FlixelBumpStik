package components.classic;

import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;
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
		var text = new FlxText(_center.x, _center.y, 0, BumpStikGame.g().i18n.tr("game/classic/allClear"), 30);
		text.autoSize = false;
		text.alignment = CENTER;

		var jackpotText = new FlxBitmapText(FlxBitmapFont.fromAngelCode(AssetPaths.Diginum__png, AssetPaths.Diginum__xml));
		jackpotText.autoSize = false;
		jackpotText.setPosition(_center.x, _center.y);
		jackpotText.scale.set(.5, .5);
		jackpotText.color = FlxColor.YELLOW;
		jackpotText.alignment = CENTER;
		jackpotText.text = Std.string(Math.min(_amount, 99999)).lpad("z", 5);

		var backdrop = new FlxSprite(_center.x, _center.y);
		backdrop.makeGraphic(Math.round(Math.max(text.width, jackpotText.width * jackpotText.scale.x)) + 16,
			Math.round(text.height + (jackpotText.height * jackpotText.scale.y)) + 16, FlxColor.TRANSPARENT);
		backdrop.drawRoundRect(1, 1, backdrop.width - 2, backdrop.height - 2, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});

		backdrop.setPosition(_center.x - backdrop.width / 2, _center.y - backdrop.height / 2);
		text.setPosition(_center.x - text.width / 2, backdrop.y + 8);
		jackpotText.setPosition(_center.x - jackpotText.width / 2, backdrop.y + backdrop.height - (jackpotText.height * .75) - 8);

		for (item in [backdrop, jackpotText, text])
		{
			item.setPosition(Math.round(item.x), Math.round(item.y));
			add(item);
		}

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
