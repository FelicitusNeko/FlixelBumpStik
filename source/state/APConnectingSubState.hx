package state;

import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class APConnectingSubState extends FlxSubState
{
	public function new()
	{
		super(FlxColor.fromRGBFloat(0, 0, 0, .5));
	}

	override function create()
	{
		var connectingText = new FlxText(0, 0, 0, "Connecting...", 20);
		connectingText.color = FlxColor.WHITE;

		var backdrop = new FlxSprite(-11, -11);
		backdrop.makeGraphic(Math.round(connectingText.width + 22), Math.round(connectingText.height + 22), FlxColor.TRANSPARENT);
		backdrop.drawRoundRect(1, 1, backdrop.width - 2, backdrop.height - 2, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});

		for (item in [backdrop, connectingText])
		{
			item.x = Math.round(item.x);
			item.y = Math.round(item.y);
			add(item);
		}

		for (item in [connectingText, backdrop])
			item.screenCenter();

		super.create();
	}
}
