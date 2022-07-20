package state;

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
		FlxG.switchState(new APGameState(_hostInput.text, Std.parseInt(_portInput.text), _slotInput.text, _pwInput.text.length > 0 ? _pwInput.text : null));
	}

	function onBack()
	{
		FlxG.switchState(new MenuState());
	}
}
