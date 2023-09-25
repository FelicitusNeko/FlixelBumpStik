package components.archipelago;

import Main.I18nFunction;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUIText;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Event;

using flixel.util.FlxSpriteUtil;

class TaskSkipSubstate extends FlxSubState
{
	var _tasks:Array<APTask> = [];
	var _tasksv2:Array<APTaskV2> = [];
	var _t:I18nFunction = null;
	var _center:FlxPoint;

	public var onTaskSkip(default, null) = new Event<APTask->Void>();

	public function new(center:FlxPoint)
	{
		_center = center;
		super(FlxColor.fromRGBFloat(0, 0, 0, .3));
	}

	override function create()
	{
		_t = BumpStikGame.g().i18n.tr;

		// var _center = new FlxPoint(camera.width / 2, camera.height / 2);
		trace(_center);
		var taskLabels = _tasksv2.map(i -> new FlxUIText(0, 0, 0, i, 16));
		var widest = .0;
		for (task in taskLabels)
			if (task.width > widest)
				widest = task.width;

		var text = new FlxText(0, 0, 0, BumpStikGame.g().i18n.tr("game/ap/skip/prompt"), 24);
		text.autoSize = false;
		text.alignment = CENTER;

		var more = "+<X>";
		var list = new FlxUIList(0, 0, cast taskLabels, widest, taskLabels[0].height, more);

		var notice = new FlxUIText(0, 0, 0, _t("game/ap/skip/notice"), 12);
		notice.autoSize = false;
		notice.alignment = CENTER;

		var accept = new FlxUIButton(0, 0, _t("game/ap/skip/confirm"), () ->
		{
			var selTask = _tasks[list.scrollIndex];
			selTask.force();
			onTaskSkip.dispatch(selTask);
			close();
		});

		var cancel = new FlxUIButton(0, 0, _t("base/dlg/cancel"), close);

		var contentHeight = Math.round(text.height + list.height + notice.height + accept.height + 40);
		var contentWidth = Math.round(Math.max(text.width, Math.max(list.width, Math.max(notice.width, accept.width + cancel.width + 10))));
		var contentTop = _center.y - (contentHeight / 2);
		trace(contentHeight, contentWidth, contentTop);

		var backdrop = new FlxSprite();
		backdrop.makeGraphic(contentWidth + 16, contentHeight + 16, FlxColor.TRANSPARENT);
		backdrop.drawRoundRect(1, 1, backdrop.width - 2, backdrop.height - 2, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});

		backdrop.setPosition(_center.x - (backdrop.width / 2), _center.y - (backdrop.height / 2));
		text.setPosition(_center.x - text.width / 2, contentTop);
		contentTop += text.height + 10;
		list.setPosition(_center.x - list.width / 2, contentTop);
		contentTop += list.height + 20;
		notice.setPosition(_center.x - notice.width / 2, contentTop);
		contentTop += notice.height + 10;
		accept.setPosition(_center.x - accept.width - 5, contentTop);
		cancel.setPosition(_center.x + 5, contentTop);

		for (item in [backdrop, text, notice, list, accept, cancel])
		{
			item.setPosition(Math.round(item.x), Math.round(item.y));
			item.scrollFactor.set(1, 1);
			add(item);
		}

		super.create();
	}

	@:allow(components.archipelago.APHUD.loadTaskSkip)
	function loadTasks(tasks:Array<APTask>)
		_tasks = tasks;

	@:allow(components.archipelago.APPlayerState.loadTaskSkip)
	function loadTasksV2(tasks:Array<APTaskV2>)
		_tasksv2 = tasks;
}
