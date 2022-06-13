import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class StandardHUD extends FlxSpriteGroup
{
	var _scoreDisplay:FlxBitmapText;

	public var score(default, set):Int;

	public function new()
	{
		var diginum = FlxBitmapFont.fromAngelCode(AssetPaths.Diginum__png, AssetPaths.Diginum__xml);
		var rightSide = FlxG.width > FlxG.height;

		_scoreDisplay = new FlxBitmapText(diginum);
		_scoreDisplay.autoSize = false;
		_scoreDisplay.setBorderStyle(FlxTextBorderStyle.SHADOW);
		_scoreDisplay.color = FlxColor.GREEN;
		_scoreDisplay.alignment = FlxTextAlign.RIGHT;
		_scoreDisplay.scale = new FlxPoint(.6, .6);

		if (rightSide)
		{
			var quarterWidth = cast(FlxG.width / 4, Int);

			super(quarterWidth * 3, 0);
			add(new FlxSprite().makeGraphic(quarterWidth, FlxG.height, FlxColor.fromRGBFloat(.1, .1, .8, .5)));

			_scoreDisplay.setPosition(quarterWidth - 20, _scoreDisplay.lineHeight);
			_scoreDisplay.width = width * (1 / _scoreDisplay.scale.x);
			add(_scoreDisplay);
			trace(x, _scoreDisplay.x);
		}
		else
		{
			super(0, FlxG.height * .8);
		}

		for (sprite in group)
			sprite.scrollFactor.set(0, 0);

		score = 0;
	}

	override function update(elapsed:Float)
	{
		score++;
	}

	function set_score(score:Int):Int
	{
		var output = Std.string(Math.min(score, 99999));
		while (output.length < 5)
			output = "z" + output;
		_scoreDisplay.text = output;

		return this.score = score;
	}
}
