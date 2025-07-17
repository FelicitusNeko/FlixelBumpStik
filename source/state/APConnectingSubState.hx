package state;

import ap.PacketTypes.NetworkItem;
import ap.Client;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

class APConnectingSubState extends FlxSubState
{
	private var _ap:Client;
	private var _items:Array<NetworkItem> = [];

	public var result(default, null) = "Unknown";
	public var slotData(default, null):Dynamic = null;
	public var items(get, null):Array<NetworkItem>;

	public function new(ap:Client)
	{
		super(FlxColor.fromRGBFloat(0, 0, 0, .5));
		_ap = ap;
	}

	private function get_items()
		return _items.slice(0);

	override function create()
	{
		var t = BumpStikGame.g().i18n.tr;

		var connectingText = new FlxText(0, 0, 0, t("menu/ap/connecting"), 20);
		connectingText.color = FlxColor.WHITE;

		var cancelButton = new FlxButton(0, 0, t("base/dlg/cancel"), () ->
		{
			result = "Cancel";
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

		_ap.onSlotRefused.add(onSlotRefused);
		_ap.onSocketDisconnected.add(onSocketDisconnected);
		_ap.onSlotConnected.add(onSlotConnected);
		_ap.onItemsReceived.add(onItemsReceived);

		super.create();
	}

	function onSlotRefused(errors:Array<String>)
	{
		trace("Slot refused", errors);
		result = errors[0];
		close();
	}

	function onSocketDisconnected()
	{
		if (result == null)
		{
			trace("Disconnected");
			result = "Disconnected";
		}
		close();
	}

	function onSlotConnected(slotData:Dynamic)
	{
		trace("Connected");
		result = "Connected";
		this.slotData = slotData;
		close();
	}

	function onItemsReceived(items:Array<NetworkItem>)
		_items = _items.concat(items);

	override function destroy()
	{
		_ap.onSlotRefused.remove(onSlotRefused);
		_ap.onSocketDisconnected.remove(onSocketDisconnected);
		_ap.onSlotConnected.remove(onSlotConnected);
		_ap.onItemsReceived.remove(onItemsReceived);
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_ap.poll();
	}
}
