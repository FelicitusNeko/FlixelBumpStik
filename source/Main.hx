package;

import components.classic.ClassicGameState;
import flixel.FlxGame;
import openfl.display.Sprite;
import state.APEntryState;
import state.MenuState;

class Main extends Sprite
{
	public function new()
	{
		super();
		#if debug
		addChild(new FlxGame(0, 0, APEntryState));
		#else
		addChild(new FlxGame(0, 0, ClassicGameState));
		#end
	}
}
