import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class StandardGUI extends FlxSpriteGroup
{
	var _scoreDisplay:FlxBitmapText;

	public var score(default, set):Int;

	public function new()
	{
		var diginum = FlxBitmapFont.fromAngelCode(AssetPaths.Diginum__png, AssetPaths.Diginum__xml);
		var rightSide = FlxG.width > FlxG.height;

		_scoreDisplay = new FlxBitmapText(diginum);
		_scoreDisplay.setBorderStyle(FlxTextBorderStyle.SHADOW);
		_scoreDisplay.alignment = FlxTextAlign.RIGHT;
		_scoreDisplay.color = FlxColor.GREEN;
		_scoreDisplay.scale = new FlxPoint(.5, .5);

		if (rightSide)
		{
			var quarterWidth = cast(FlxG.width / 4, Int);

			super(quarterWidth * 3, 0);
			add(new FlxSprite().makeGraphic(quarterWidth, FlxG.height, FlxColor.fromRGBFloat(.1, .1, .8, .5)));

			_scoreDisplay.x = quarterWidth - 20;
			_scoreDisplay.y = _scoreDisplay.height * 2;
			add(_scoreDisplay);
		}
		else
		{
			super(0, FlxG.height * .8);
		}

		for (sprite in group)
			sprite.scrollFactor.set(0, 0);

		score = 12345;
	}

	function set_score(score:Int):Int
	{
		_scoreDisplay.text = Std.string(Math.min(score, 99999));
		// _scoreDisplay.x = x + width - 20 - (_scoreDisplay.textWidth * scale.x);
		_scoreDisplay.x = 0;
		return this.score = score;
	}
}
