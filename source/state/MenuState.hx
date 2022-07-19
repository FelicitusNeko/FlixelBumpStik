package state;

import components.classic.ClassicGameState;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

class MenuState extends FlxState
{
	var titleText:FlxText;
	var playButton:FlxButton;
	var apButton:FlxButton;
	#if desktop
	var exitButton:FlxButton;
	#end

	override public function create()
	{
		titleText = new FlxText(20, 0, 0, "Bumper\nStickers", 22);
		titleText.alignment = CENTER;
		titleText.screenCenter(X);
		add(titleText);

		playButton = new FlxButton(0, 0, "Classic Mode", clickPlay);
		// playButton.onUp.sound = FlxG.sound.load(AssetPaths.select__wav);
		playButton.x = (FlxG.width / 2) - 10 - playButton.width;
		playButton.y = FlxG.height - playButton.height - 10;
		add(playButton);

		apButton = new FlxButton(0, 0, "Archipelago Mode", clickAP);
		apButton.x = (FlxG.width / 2) + 10;
		apButton.y = FlxG.height - apButton.height - 10;
		add(apButton);

		#if desktop
		exitButton = new FlxButton(FlxG.width - 28, 8, "X", clickExit);
		exitButton.loadGraphic(AssetPaths.button__png, true, 20, 20);
		add(exitButton);
		#end

		// if (FlxG.sound.music == null) // don't restart the music if it's already playing
		// {
		// 	FlxG.sound.playMusic(AssetPaths.HaxeFlixel_Tutorial_Game__ogg, 1, true);
		// }

		// FlxG.camera.fade(FlxColor.BLACK, 0.33, true);

		super.create();
	}

	function clickPlay()
	{
		// FlxG.camera.fade(FlxColor.BLACK, 0.33, false, function()
		// {
		// 	FlxG.switchState(new PlayState());
		// });
		FlxG.switchState(new ClassicGameState());
	}

	function clickAP()
	{
		// FlxG.camera.fade(FlxColor.BLACK, 0.33, false, function()
		// {
		// 	FlxG.switchState(new OptionsState());
		// });
		FlxG.switchState(new APEntryState());
	}

	#if desktop
	function clickExit()
	{
		Sys.exit(0);
	}
	#end
}
