package state;

import ap.Client;
import components.archipelago.APGameState;
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

	override function create()
	{
		var titleText = new FlxText(20, 0, 0, "Archipelago", 22);
		titleText.alignment = CENTER;
		titleText.screenCenter(X);
		add(titleText);

		var playButton = new FlxButton(0, 0, "Play", onPlay);
		// playButton.onUp.sound = FlxG.sound.load(AssetPaths.select__wav);
		playButton.x = (FlxG.width / 2) - 10 - playButton.width;
		playButton.y = FlxG.height - playButton.height - 10;
		add(playButton);

		var backButton = new FlxButton(0, 0, "Back", onBack);
		backButton.x = (FlxG.width / 2) + 10;
		backButton.y = FlxG.height - backButton.height - 10;
		add(backButton);

		var hostLabel = new FlxText(FlxG.width / 2 - 100, 80, 0, "Host", 12);
		_hostInput = new FlxInputText(FlxG.width / 2, 80, 150, "localhost", 12, FlxColor.WHITE, FlxColor.GRAY);
		add(hostLabel);
		add(_hostInput);

		var portLabel = new FlxText(FlxG.width / 2 - 100, 100, 0, "Port", 12);
		_portInput = new FlxInputText(FlxG.width / 2, 100, 150, "38281", 12, FlxColor.WHITE, FlxColor.GRAY);
		add(portLabel);
		add(_portInput);

		var slotLabel = new FlxText(FlxG.width / 2 - 100, 120, 0, "Slot Name", 12);
		_slotInput = new FlxInputText(FlxG.width / 2, 120, 150, "", 12, FlxColor.WHITE, FlxColor.GRAY);
		add(slotLabel);
		add(_slotInput);

		var pwLabel = new FlxText(FlxG.width / 2 - 100, 140, 0, "Password", 12);
		_pwInput = new FlxInputText(FlxG.width / 2, 140, 150, "", 12, FlxColor.WHITE, FlxColor.GRAY);
		add(pwLabel);
		add(_pwInput);

		super.create();
	}

	function onPlay()
	{
		var port = Std.parseInt(_portInput.text);
		if (_hostInput.text == "")
			openSubState(new APErrorSubState("Host name cannot be empty. (That's the address of the server you're connecting to.)"));
		else if (_portInput.text == "")
			openSubState(new APErrorSubState("Port number cannot be empty. (That's the 4-5 digits at the end of the server address, often 38281.)"));
		else if (!~/^\d+$/.match(_portInput.text))
			openSubState(new APErrorSubState("Port must be numeric."));
		else if (port <= 0 || port > 65535)
			openSubState(new APErrorSubState("Port should be a number from 1 to 65535 (most likely 38281)."));
		else if (_slotInput.text == "")
			openSubState(new APErrorSubState("Slot name cannot be empty. (That's your name on your YAML configuration file.)"));
		else
		{
			var connectSubState = new APConnectingSubState();
			openSubState(connectSubState);

			var ap = new Client("BumpStik", "Bumper Stickers", "ws://" + _hostInput.text + ":" + _portInput.text);

			ap._hOnRoomInfo = () -> ap.ConnectSlot(_slotInput.text, _pwInput.text.length > 0 ? _pwInput.text : null, 0x7, ["AP", "Testing"],
				{major: 0, minor: 3, build: 3});

			ap._hOnSlotRefused = (errors:Array<String>) ->
			{
				var error = "An unknown error occurred: ";
				switch (errors[0])
				{
					case "InvalidSlot": error = "No player \"" + _slotInput.text + "\" is listed for this server instance.";
					case "InvalidGame": error = "Player \"" + _slotInput.text + "\" is not listed as a Bumper Stickers slot.";
					case "IncompatibleVersion": error = "The server is expecting a newer version of the game. Please ensure you're running the latest version.";
					case "InvalidPassword": error = "The password supplied is incorrect.";
					case "InvalidItemsHandling": error = "Please report a bug stating that an \"InvalidItemsHandling\" error was received.";
					default: error += errors[0];
				}
				openSubState(new APErrorSubState(error));
			}

			ap._hOnSocketDisconnected = () -> openSubState(new APErrorSubState("The server closed the connection."));

			ap._hOnSlotConnected = (slotData:Dynamic) ->
			{
				ap._hOnSocketDisconnected = null;
				FlxG.switchState(new APGameState(ap, slotData));
			}
		}
	}

	function onBack()
	{
		FlxG.switchState(new MenuState());
	}
}
