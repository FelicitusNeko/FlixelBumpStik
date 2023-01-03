package state;

import haxe.Timer;
import Main.I18nFunction;
import ap.Client;
import components.archipelago.APGameState;
import components.dialogs.DialogBox;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.ui.FlxInputText;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

class APEntryState extends FlxState
{
	private var _hostInput:FlxInputText;
	private var _portInput:FlxInputText;
	private var _slotInput:FlxInputText;
	private var _pwInput:FlxInputText;

	/** I18n function. **/
	private var _t:I18nFunction;

	private var _tabOrder:Array<FlxInputText> = [];

	override function create()
	{
		_t = BumpStikGame.g().i18n.tr;

		var titleText = new FlxText(20, 0, 0, "Archipelago", 22);
		titleText.alignment = CENTER;
		titleText.screenCenter(X);
		add(titleText);

		var playButton = new FlxButton(0, 0, _t("base/play"), onPlay);
		// playButton.onUp.sound = FlxG.sound.load(AssetPaths.select__wav);
		playButton.x = (FlxG.width / 2) - 10 - playButton.width;
		playButton.y = FlxG.height - playButton.height - 10;
		add(playButton);

		var backButton = new FlxButton(0, 0, _t("base/back"), onBack);
		backButton.x = (FlxG.width / 2) + 10;
		backButton.y = FlxG.height - backButton.height - 10;
		add(backButton);

		var hostLabel = new FlxText(FlxG.width / 2 - 100, 80, 0, _t("menu/ap/host"), 12);
		_hostInput = new FlxInputText(FlxG.width / 2, 80, 150, "localhost", 12, FlxColor.WHITE, FlxColor.GRAY);
		add(hostLabel);
		add(_hostInput);

		var portLabel = new FlxText(FlxG.width / 2 - 100, 100, 0, _t("menu/ap/port"), 12);
		_portInput = new FlxInputText(FlxG.width / 2, 100, 150, "38281", 12, FlxColor.WHITE, FlxColor.GRAY);
		_portInput.filterMode = FlxInputText.ONLY_NUMERIC;
		_portInput.maxLength = 6;
		add(portLabel);
		add(_portInput);

		var slotLabel = new FlxText(FlxG.width / 2 - 100, 120, 0, _t("menu/ap/slot"), 12);
		_slotInput = new FlxInputText(FlxG.width / 2, 120, 150, "", 12, FlxColor.WHITE, FlxColor.GRAY);
		add(slotLabel);
		add(_slotInput);

		var pwLabel = new FlxText(FlxG.width / 2 - 100, 140, 0, _t("menu/ap/pw"), 12);
		_pwInput = new FlxInputText(FlxG.width / 2, 140, 150, "", 12, FlxColor.WHITE, FlxColor.GRAY);
		_pwInput.passwordMode = true;
		add(pwLabel);
		add(_pwInput);

		_tabOrder = [_hostInput, _portInput, _slotInput, _pwInput];

		super.create();
	}

	function onPlay()
	{
		inline function postError(str:String, ?vars:Map<String, Dynamic>)
			openSubState(new DialogBox(_t('menu/ap/error/$str', vars), {
				title: _t("base/error"),
				titleColor: FlxColor.fromRGBFloat(1, .5, .5),
				defAccept: Close,
				defCancel: Close
			}));

		var port = Std.parseInt(_portInput.text);
		if (_hostInput.text == "")
			postError('noHost');
		else if (_portInput.text == "")
			postError('noPort');
		else if (!~/^\d+$/.match(_portInput.text))
			postError('portNonNumeric');
		else if (port <= 0 || port > 65535)
			postError('portOutOfRange');
		else if (_slotInput.text == "")
			postError('noSlot');
		else
		{
			var connectSubState = new APConnectingSubState();
			openSubState(connectSubState);

			var ap = new Client("BumpStik", "Bumper Stickers", 'ws://${_hostInput.text}:${_portInput.text}');

			ap._hOnRoomInfo = () ->
			{
				trace("Got room info - sending connect packet");
				ap.ConnectSlot(_slotInput.text, _pwInput.text.length > 0 ? _pwInput.text : null, 0x7, ["AP", "Testing"], {major: 0, minor: 3, build: 7});
			};

			var polltimer = new Timer(50);
			polltimer.run = ap.poll;

			ap._hOnSlotRefused = (errors:Array<String>) ->
			{
				trace("Slot refused", errors);
				closeSubState();
				switch (errors[0])
				{
					case x = "InvalidSlot" | "InvalidGame": postError(x, ["name" => _slotInput.text]);
					case x = "IncompatibleVersion" | "InvalidPassword" | "InvalidItemsHandling": postError(x);
					case x: postError("default", ["error" => x]);
				}
			}

			ap._hOnSocketDisconnected = () ->
			{
				polltimer.stop();
				trace("Disconnected");
				closeSubState();
				postError("connectionReset");
			};

			ap._hOnSlotConnected = (slotData:Dynamic) ->
			{
				trace("Connected - switching to game state");
				polltimer.stop();
				ap._hOnRoomInfo = null;
				ap._hOnSlotRefused = null;
				ap._hOnSocketDisconnected = null;
				ap._hOnSlotConnected = null;
				closeSubState();
				FlxG.switchState(new APGameState(ap, slotData));
			}
		}
	}

	function onBack()
	{
		FlxG.switchState(new MenuState());
	}

	// override function update(elapsed:Float)
	// {
	// 	super.update(elapsed);
	// 	if (FlxG.keys.anyJustPressed([TAB, ENTER]))
	// 	{
	// 		var curFocus:Null<FlxInputText> = null;
	// 		for (textbox in _tabOrder)
	// 			if (textbox.hasFocus)
	// 				curFocus = textbox;
	// 		if (curFocus != null)
	// 		{
	// 			if (FlxG.keys.anyJustPressed([ENTER]))
	// 			{
	// 				// connect to the server
	// 			}
	// 			else // it's TAB
	// 			{
	// 				var focusIndex = _tabOrder.indexOf(curFocus);
	// 				trace('Focus found on TAB event at index $focusIndex');
	// 				if (FlxG.keys.checkStatus(SHIFT, PRESSED))
	// 					focusIndex += _tabOrder.length - 1;
	// 				else
	// 					focusIndex++;
	// 				curFocus.hasFocus = false;
	// 				curFocus.text = curFocus.text.substr(0, curFocus.text.length - 1);
	// 				_tabOrder[focusIndex % _tabOrder.length].hasFocus = true;
	// 			}
	// 		}
	// 		else
	// 			trace("Focus not found");
	// 	}
	// }
}
