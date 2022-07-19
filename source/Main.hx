package;

import flixel.FlxGame;
import openfl.display.Sprite;
import state.MenuState;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, MenuState));
	}
}
