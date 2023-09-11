package components.archipelago;

import ap.Client;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import lime.app.Event;

using flixel.util.FlxSpriteUtil;

class APDisconnectSubState extends FlxSubState
{
	public var onCancel(default, null) = new Event<Void->Void>();
	public var onReconnect(default, null) = new Event<Void->Void>();

	private var _ap:Client;
	private var _seed:String;
	private var _bc:FlxPoint;

	public function new(ap:Client, boardCenter:FlxPoint)
	{
		super(FlxColor.fromRGBFloat(0, 0, 0, .5));
		_ap = ap;
		_seed = _ap.seed;
		_bc = boardCenter;

		_ap._hOnRoomInfo = () ->
		{
			if (_seed != _ap.seed)
			{
				trace("Seed mismatch; aborting connection");
				_ap.disconnect_socket();
				onCancel.dispatch();
				close();
			}
			else
			{
				trace("Got room info - sending connect packet");

				#if debug
				var tags = ["AP", "Testing"];
				#else
				var tags = ["AP"];
				#end
				ap.ConnectSlot(_ap.slot, null, 0x7, tags, {major: 0, minor: 3, build: 8}); // HACK: this is not retransmitting the password
			}
		};

		_ap._hOnSlotRefused = (_) -> onCancel.dispatch();

		_ap._hOnSocketDisconnected = onCancel.dispatch;

		_ap._hOnSlotConnected = (slotData:Dynamic) ->
		{
			trace("Connected - returning to game state");
			ap._hOnRoomInfo = () -> {};
			ap._hOnSlotRefused = (_) -> {};
			ap._hOnSocketDisconnected = () -> {};
			ap._hOnSlotConnected = (_) -> {};
			onReconnect.dispatch();
			close();
		}
	}

	override function create()
	{
		var t = BumpStikGame.g().i18n.tr;

		var dcText = new FlxText(0, 0, 0, t("menu/ap/disconnected"), 20);
		dcText.color = FlxColor.WHITE;

		var dcCaption = new FlxText(0, 0, 0, t("menu/ap/disconnectMsg"));
		dcCaption.color = FlxColor.WHITE;

		var cancelButton = new FlxButton(0, 0, t("base/dlg/cancel"), () ->
		{
			onCancel.dispatch();
			close();
		});
		cancelButton.scrollFactor.set(1, 1);

		var backdrop = new FlxSprite(-11, -11);
		backdrop.makeGraphic(Math.round(Math.max(dcText.width + 22, dcCaption.width + 12)),
			Math.round(dcText.height + dcCaption.height + cancelButton.height + 32), FlxColor.TRANSPARENT);
		backdrop.drawRoundRect(1, 1, backdrop.width - 2, backdrop.height - 2, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});

		backdrop.setPosition(_bc.x - (backdrop.width / 2), _bc.y - (backdrop.height / 2));
		for (item in [dcText, dcCaption, cancelButton])
			item.x = _bc.x - (item.width / 2);

		dcText.y = backdrop.y + 5;
		dcCaption.y = dcText.y + dcText.height + 5;
		cancelButton.y = dcCaption.y + dcCaption.height + 5;

		for (item in [backdrop, dcText, dcCaption, cancelButton])
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
