package state;

import flixel.FlxState;
import flixel.text.FlxText;

class APEntryState extends FlxState
{
	override function create()
	{
		var titleText = new FlxText(20, 0, 0, "Options", 22);
		titleText.alignment = CENTER;
		titleText.screenCenter(X);
		add(titleText);

		super.create();
	}
}
