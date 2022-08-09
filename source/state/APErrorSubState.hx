package state;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class APErrorSubState extends FlxSubState
{
	public var message(default, null):String;

	public function new(message:String)
	{
		this.message = message;
		super(FlxColor.fromRGBFloat(0, 0, 0, 0.5));
	}

	override function create()
	{
		var _t = BumpStikGame.g().i18n.tr;

		var errorText = new FlxText(0, 0, 0, _t("base/error"), 20);
		errorText.color = FlxColor.fromRGBFloat(1, .5, .5);

		var messageText = new FlxText(0, 0, 0, message, 12);
		messageText.fieldWidth = Math.min(messageText.fieldWidth, 400);
		messageText.color = FlxColor.WHITE;
		messageText.alignment = CENTER;

		var closeButton = new FlxButton(0, 0, _t("base/close"), close);

		var backdrop = new FlxSprite(-11, -11);
		backdrop.makeGraphic(Math.round(Math.max(errorText.width, messageText.width) + 22),
			Math.round(errorText.height + messageText.height + closeButton.height + 40), FlxColor.TRANSPARENT);
		backdrop.drawRoundRect(1, 1, backdrop.width - 2, backdrop.height - 2, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});

		backdrop.screenCenter();
		for (item in [errorText, messageText, closeButton])
			item.screenCenter(X);

		errorText.y = backdrop.y + 10;
		messageText.y = errorText.y + errorText.height + 10;
		closeButton.y = messageText.y + messageText.height + 10;

		for (item in [backdrop, errorText, messageText, closeButton])
		{
			item.x = Math.round(item.x);
			item.y = Math.round(item.y);
			add(item);
		}

		super.create();
	}

	#if !(FLX_NO_KEYBOARD)
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.ENTER)
			close();
	}
	#end
}
