package state;

import ap.Client;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import lime.app.Event;

using flixel.util.FlxSpriteUtil;

class APConnectingSubState extends FlxSubState
{
	public var onCancel(default, null) = new Event<Void->Void>();

	private var _ap:Client;

	public function new(ap:Client)
	{
		super(FlxColor.fromRGBFloat(0, 0, 0, .5));
		_ap = ap;
	}

	override function create()
	{
		var t = BumpStikGame.g().i18n.tr;

		var connectingText = new FlxText(0, 0, 0, t("menu/ap/connecting"), 20);
		connectingText.color = FlxColor.WHITE;

		var cancelButton = new FlxButton(0, 0, t("base/dlg/cancel"), () ->
		{
			onCancel.dispatch();
			close();
		});

		var backdrop = new FlxSprite(-11, -11);
		backdrop.makeGraphic(Math.round(connectingText.width + 22), Math.round(connectingText.height + cancelButton.height + 27), FlxColor.TRANSPARENT);
		backdrop.drawRoundRect(1, 1, backdrop.width - 2, backdrop.height - 2, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});

		backdrop.screenCenter();
		for (item in [connectingText, cancelButton])
			item.screenCenter(X);

		connectingText.y = backdrop.y + 5;
		cancelButton.y = connectingText.y + connectingText.height + 5;

		for (item in [backdrop, connectingText, cancelButton])
		{
			item.x = Math.round(item.x);
			item.y = Math.round(item.y);
			add(item);
		}

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_ap.poll();
	}
}
