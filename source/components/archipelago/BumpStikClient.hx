package components.archipelago;

import ap.Client;

class BumpStikClient extends Client
{
	public var _slotName:String;

	public var _password:Null<String>;

	public var checkQueue(get, null):Array<Int> = [];

	public function new(slotName:String, game, uri, ?password)
	{
		super('BumpStik-${slotName}', game, uri);
		_slotName = slotName;
		_password = password;
		onRoomInfo.add(onRoomInfoH, -100);
		onSlotConnected.add(onSlotConnectedH);
	}

	public function get_checkQueue()
		return this.checkQueue.slice(0);

	function onSlotConnectedH(_)
	{
		if (_checkQueue.length > 0)
		{
			super.LocationChecks(checkQueue);
			checkQueue = [];
		}
	}

	function onRoomInfoH()
	{
		#if debug
		var tags = ["AP", "Testing"];
		#else
		var tags = ["AP"];
		#end
		ConnectSlot(_slotName, _password, 0x7, tags, {major: 0, minor: 4, build: 3});
	}

	public override function LocationChecks(locations:Array<Int>):Bool
	{
		if (state == SLOT_CONNECTED)
			return super.LocationChecks(locations);
		else
		{
			checkQueue = checkQueue.concat(locations);
			return false;
		}
	}
}
