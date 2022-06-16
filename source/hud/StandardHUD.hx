package hud;

import boardObject.Bumper;
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
	/** The diginum respresentation of the current score. **/
	var _scoreDisplay:FlxBitmapText;

	/** The diginum respresentation of the current clear count. **/
	var _blockDisplay:FlxBitmapText;

	/** Whether the HUD is displayed on the right side (`true`) or bottom (`false`). **/
	var _rightSide = true;

	/** The current score displayed on the HUD. **/
	public var score(default, set):Int;

	/** The current count of cleared bumpers displayed on the HUD. **/
	public var block(default, set):Int;

	/** The current next bumper displayed on the HUD. **/
	public var nextBumper(default, set):Bumper = null;

	public function new()
	{
		var diginum = FlxBitmapFont.fromAngelCode(AssetPaths.Diginum__png, AssetPaths.Diginum__xml);
		_rightSide = FlxG.width > FlxG.height;

		_scoreDisplay = new FlxBitmapText(diginum);
		_blockDisplay = new FlxBitmapText(diginum);

		for (display in [_scoreDisplay, _blockDisplay])
		{
			display.autoSize = false;
			display.setBorderStyle(FlxTextBorderStyle.SHADOW);
			display.alignment = FlxTextAlign.RIGHT;
			display.scale = new FlxPoint(.6, .6);
		}
		_scoreDisplay.color = FlxColor.GREEN;
		_blockDisplay.color = FlxColor.RED;

		if (_rightSide)
		{
			var quarterWidth = Math.round(FlxG.width / 4);

			super(quarterWidth * 3, 0);
			add(new FlxSprite().makeGraphic(quarterWidth, FlxG.height, FlxColor.fromRGBFloat(.1, .1, .8, .5)));

			_scoreDisplay.setPosition(quarterWidth - 20, _scoreDisplay.lineHeight);
			_scoreDisplay.width = width * (1 / _scoreDisplay.scale.x);
			add(_scoreDisplay);

			_blockDisplay.setPosition(quarterWidth - 20, _blockDisplay.lineHeight * 2);
			_blockDisplay.width = width * (1 / _blockDisplay.scale.x);
			add(_blockDisplay);
		}
		else
		{
			super(0, FlxG.height * .8);
		}

		for (sprite in group)
			sprite.scrollFactor.set(0, 0);

		score = 0;
		block = 0;
	}

	function set_score(score:Int):Int
	{
		var output = Std.string(Math.min(score, 99999));
		while (output.length < 5)
			output = "z" + output;
		_scoreDisplay.text = output;

		return this.score = score;
	}

	function set_block(block:Int):Int
	{
		var output = Std.string(Math.min(block, 99999));
		while (output.length < 5)
			output = "z" + output;
		_blockDisplay.text = output;

		return this.block = block;
	}

	function set_nextBumper(nextBumper:Bumper):Bumper
	{
		if (this.nextBumper != null)
		{
			remove(this.nextBumper);
			this.nextBumper.scrollFactor.set(1, 1);
		}
		if (nextBumper != null)
		{
			nextBumper.setPosition(width - nextBumper.width - 5, height - nextBumper.height - 5);
			add(nextBumper);
			nextBumper.scrollFactor.set(0, 0);
		}
		return this.nextBumper = nextBumper;
	}
}
