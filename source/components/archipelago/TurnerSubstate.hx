package components.archipelago;

import boardObject.BoardObject;
import boardObject.Bumper;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import lime.app.Event;

using flixel.util.FlxSpriteUtil;

class TurnerSubstate extends FlxSubState
{
	private var _bumpers = new FlxTypedGroup<Bumper>();

	public var center(default, null):FlxPoint;

	public var onDialogResult(default, null) = new Event<Null<Direction>->Void>();

	private var _curDir:Direction;

	private var _color:FlxColor;

	private var _dirs:Array<Direction> = [Up, Right, Down, Left];

	public function new(center:FlxPoint, curDir:Direction, color:FlxColor)
	{
		this.center = center;
		this._curDir = curDir;
		this._color = color;

		super(FlxColor.fromRGBFloat(0, 0, 0, .3));
	}

	override function create()
	{
		super.create();

		var distanceFactor = .8;
		var bumperHeight:Float = -1;

		var cancelButton = new FlxSpriteButton(center.x, center.y, null, () -> onDialogResult.dispatch(null));
		cancelButton.scrollFactor.set(1, 1);
		cancelButton.makeGraphic(64, 64, FlxColor.TRANSPARENT);

		for (i => dir in _dirs)
		{
			var bumper = new Bumper(center.x, center.y, _color, dir);
			if (bumperHeight < 0)
				bumperHeight = bumper.height;
			bumper.x += Math.cos(BumpStikGame.DegRad((i - 1) * 90)) * (bumperHeight * distanceFactor);
			bumper.y += Math.sin(BumpStikGame.DegRad((i - 1) * 90)) * (bumperHeight * distanceFactor);
			bumper.grayedOut = dir == _curDir;
			bumper.scale.set(.5, .5);
			_bumpers.add(bumper);
		}

		cancelButton.drawCircle(32, 32, 30, FlxColor.BLACK, {thickness: 3, color: FlxColor.RED}, {smoothing: true});
		cancelButton.alpha = .75;
		add(cancelButton);

		var cancelText = new FlxText(center.x + (bumperHeight / 2) - 36, center.y + (bumperHeight / 2), 72, "Cancel", 14);
		cancelText.alignment = CENTER;
		cancelText.y -= cancelText.height / 2;
		add(cancelText);

		for (bumper in _bumpers)
			bumper.onClick.add(onClickBumper);
		add(_bumpers);

		onDialogResult.add(onDialogResultF);
	}

	function onClickBumper(obj:BoardObject)
	{
		if (!Std.isOfType(obj, Bumper))
			return;
		var bumper = cast(obj, Bumper);
		if (!bumper.grayedOut)
			onDialogResult.dispatch(bumper.direction);
	}

	function onDialogResultF(_:Direction)
		close();
}
