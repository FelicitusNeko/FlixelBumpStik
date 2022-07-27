package components.archipelago;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.Timer;
import lime.app.Event;

using flixel.util.FlxSpriteUtil;

class APToast extends FlxSpriteGroup
{
	public var onFinish(default, null) = new Event<Void->Void>();

	private var _delay:Int;

	public function new(x:Float, y:Float, message:String, color = FlxColor.WHITE, delay = 2000)
	{
		super(x, y);

		var text = new FlxText(6, 6, 0, message, 14);
		text.color = FlxColor.BLACK;

		var bg = new FlxSprite(0, 0);
		bg.makeGraphic(Math.round(text.width) + 12, Math.round(text.height) + 12, FlxColor.TRANSPARENT);
		bg.drawRoundRect(1, 1, bg.width - 2, bg.height - 2, 20, 20, color);

		add(bg);
		add(text);

		_delay = delay;
	}

	public function slideIn()
	{
		FlxTween.tween(this, {y: this.y - (this.height * 1.5)}, .5, {
			ease: FlxEase.circOut,
			onComplete: _ ->
			{
				Timer.delay(slideOut, _delay);
			}
		});
	}

	public function slideOut()
	{
		FlxTween.tween(this, {y: this.y + (this.height * 1.5)}, .5, {
			ease: FlxEase.circIn,
			onComplete: _ ->
			{
				kill();
				onFinish.dispatch();
			}
		});
	}
}
