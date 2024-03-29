package components;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class HUDCounter extends FlxSpriteGroup
{
	public var label(default, null):String;
	public var value(default, set):Int;
	public var maxLength(default, set) = 5;

	public var counterColor(get, set):FlxColor;

	private var _counterText:FlxBitmapText;

	public function new(x:Float, y:Float, label:String, value = 0)
	{
		super(x, y);

		var labelText = new FlxText(0, 0, 0, label, 16);

		_counterText = new FlxBitmapText(FlxBitmapFont.fromAngelCode(AssetPaths.Diginum__png, AssetPaths.Diginum__xml));
		_counterText.autoSize = false;
		_counterText.setBorderStyle(FlxTextBorderStyle.SHADOW);
		_counterText.scale = new FlxPoint(.6, .6);

		this.label = label;
		this.value = value;

		var bg = new FlxSprite(0, labelText.height);
		bg.makeGraphic(136, 44, FlxColor.BLACK);

		add(bg);
		add(labelText);
		add(_counterText);
	}

	function set_value(value:Int)
	{
		if (_counterText != null)
			_counterText.text = Std.string(Math.min(value, Math.pow(10, maxLength) - 1)).lpad("z", maxLength);
		return this.value = value;
	}

	function set_maxLength(maxLength:Int)
	{
		this.maxLength = maxLength;
		if (_counterText != null)
			value = value;
		return maxLength;
	}

	function get_counterColor()
	{
		return _counterText.color;
	}

	function set_counterColor(counterColor:FlxColor)
	{
		return _counterText.color = counterColor;
	}
}
