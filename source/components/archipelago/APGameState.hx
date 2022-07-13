package components.archipelago;

import ap.Client;
import ap.PacketTypes.NetworkItem;
import components.classic.ClassicGameState;
import haxe.Template;
import helder.Set;

@:enum
abstract APLocation(Int)
{
	var Points500 = 0;
	var Points1000 = 1;
	var Points1500 = 2;
	var Points2000 = 3;
	var Points2500 = 4;
	var Points3000 = 5;
	var Points3500 = 6;
	var Points4000 = 7;
	var Combo4 = 8;
	var Combo5 = 9;
	var Combo6 = 10;
	var Chain2 = 11;
	var Chain3 = 12;
	var AllClear = 13;
	var Booster1 = 14;
	var Booster2 = 15;
	var Booster3 = 16;
	var Booster4 = 17;
	var Booster5 = 18;
	var ClearedHazards = 19;

	@:to
	public inline function fromLocation():Int
	{
		return this + 0; // TOOD: replace 0 with location offset
	}
}

@:enum
abstract APItem(Int)
{
	var BoardWidth = 0;
	var BoardHeight = 1;
	var MinColor = 2;
	var MaxColor = 3;
	var StartPaintCan = 4;
	var BonusBooster = 5;
	var HazardBumper = 6;

	@:to
	public inline function fromItem():Int
	{
		return this + 0; // TOOD: replace 0 with item offset
	}
}

class APGameState extends ClassicGameState
{
	private var _curWidth = 3;
	private var _curHeight = 3;
	private var _startColors = 2;
	private var _endColors = 3;
	private var _startPaintCans = 0;
	private var _hazardBumpers = 0;

	private var _completedChecks:Set<APLocation>;
	private var _ap:Client;

	public function new(host:String, port:Int, slotName:String, ?password:String)
	{
		// TODO: UUID
		_ap = new Client("asdf", "Bumper Stickers", "ws://" + host + ":" + port);

		_ap._hOnSlotRefused = onSlotRefused;
		_ap._hOnItemsReceived = onItemsReceived;

		_ap.ConnectSlot(slotName, password, 0x7);
	}

	override function create()
	{
		if (_players.length == 0)
			_players.push({
				board: new APBoard(0, 0, _curWidth, _curHeight),
				multStack: [1, 1]
			});

		super.create();
	}

	private function onItemsReceived(items:Array<NetworkItem>)
	{
		for (item in items)
		{
			switch (cast(item.item, APItem))
			{
				case BoardWidth:
					_curWidth++;
				case BoardHeight:
					_curHeight++;
				case MinColor:
					_startColors++;
				case MaxColor:
					_endColors++;
				case StartPaintCans:
					_startPaintCans++;
					_hudClassic.paintCans++;
				case BonusBooster:
					_player.multStack[1] += .2;
				case HazardBumper:
					_hazardBumpers++;
					// TODO: implement
			}
		}
	}

	private function onSlotRefused(errors:Array<String>)
	{
		// TODO: handle failure to connect
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		_ap.poll();
	}
}
