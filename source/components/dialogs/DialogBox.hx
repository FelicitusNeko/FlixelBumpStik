package components.dialogs;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

/** The result of the dialog box. **/
enum DialogResult
{
	Yes;
	No;
	Ok;
	Cancel;
	Close;

	/** Can be used if the dialog box should return some other data. **/
	Other(v:Dynamic);

	/** A custom resolver can perform additional functions before closing the dialog. Its callback returns the final result. **/
	Custom(f:Void->Null<DialogResult>);
}

/** A button to be provided in the dialog box. **/
typedef DialogButton =
{
	/** The text for this dialog box. **/
	var text:String;

	/** The result (if any) to be provided if the button is clicked. **/
	var ?result:DialogResult;
}

/** Options for the dialog box. **/
typedef DialogOptions =
{
	/** The dialog box's title. Defaults to the localized string for "Notice". **/
	var ?title:String;

	/** The text color for the dialog box's title. Defaults to `FlxColor.WHITE`. **/
	var ?titleColor:FlxColor;

	/** The color for the dialog box's message body. Defaults to `FlxColor.WHITE`. **/
	var ?bodyColor:FlxColor;

	/** The list of buttons for this dialog. Defaults to one "Close" button. **/
	var ?buttons:Array<DialogButton>;

	/** The result to resolve if the user presses Enter on a keyboard-enabled platform. If none is specified, the functionality is disabled. **/
	var ?defAccept:DialogResult;

	/** The result to resolve if the user presses Escape on a keyboard-enabled platform. If none is specified, the functionality is disabled. **/
	var ?defCancel:DialogResult;
}

/** Provides a configurable all-purpose dialog box. **/
class DialogBox extends FlxSubState
{
	/** The title for this dialog box. **/
	public var title(get, never):String;

	/** The message body for this dialog box. **/
	public var message(default, null):String;

	/** The result of this dialog box, if any. **/
	public var result(default, null):Null<DialogResult> = null;

	/** The build options passed to the dialog box. **/
	var opts:DialogOptions = {};

	public function new(message:String, ?opts:DialogOptions)
	{
		if (opts != null)
			this.opts = opts;
		this.message = message;
		super(FlxColor.fromRGBFloat(0, 0, 0, 0.5));
	}

	override function create()
	{
		var _t = BumpStikGame.g().i18n.tr;

		var title = new FlxText(0, 0, 0, this.title == null ? _t("base/dlg/notice") : this.title, 20);
		title.color = opts.titleColor != null ? opts.titleColor : FlxColor.WHITE;

		var body = new FlxText(0, 0, 0, message, 12);
		body.fieldWidth = Math.min(body.fieldWidth, 400);
		body.color = opts.bodyColor != null ? opts.bodyColor : FlxColor.WHITE;
		body.alignment = CENTER;

		var buttons = opts.buttons != null ? opts.buttons : [];
		if (buttons.length == 0)
			buttons.push({text: _t("base/dlg/close"), result: Close});

		var buttonCtls = buttons.map(i -> new FlxButton(0, 0, i.text, () -> resolve(i.result)));

		var backdrop = new FlxSprite(-11, -11);
		backdrop.makeGraphic(Math.round(Math.max(Math.max(title.width, body.width), (buttonCtls[0].width + 10) * buttonCtls.length) + 22),
			Math.round(title.height + body.height + buttonCtls[0].height + 40), FlxColor.TRANSPARENT);
		backdrop.drawRoundRect(1, 1, backdrop.width - 2, backdrop.height - 2, 20, 20, FlxColor.BLACK, {color: FlxColor.WHITE, thickness: 3});

		backdrop.screenCenter();

		for (item in [title, body])
			item.screenCenter(X);

		title.y = backdrop.y + 10;
		body.y = title.y + title.height + 10;

		{
			var offsetUnit = buttonCtls[0].width + 10,
				firstX = (FlxG.width / 2) - ((offsetUnit / 2) * buttonCtls.length) + 5;
			for (x => button in buttonCtls)
				button.setPosition(firstX + (offsetUnit * x), body.y + body.height + 10);
		}

		for (item in [backdrop, title, body])
		{
			item.x = Math.round(item.x);
			item.y = Math.round(item.y);
			add(item);
		}
		for (button in buttonCtls)
		{
			button.x = Math.round(button.x);
			button.y = Math.round(button.y);
			add(button);
		}

		super.create();
	}

	function get_title()
		return opts.title == null ? BumpStikGame.g().i18n.tr('base/notice') : opts.title;

	/**
		Resolves the dialog box.
		@param result The result of the dialog box. If this is Custom, the callback it provides will be called.
	**/
	function resolve(?result:DialogResult)
	{
		this.result = switch (result)
		{
			case Custom(f):
				f();
			default: result;
		}
		close();
	}

	#if !(FLX_NO_KEYBOARD)
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE && Reflect.hasField(opts, "defCancel"))
			resolve(opts.defCancel);
		else if (FlxG.keys.justPressed.ENTER && Reflect.hasField(opts, "defAccept"))
			resolve(opts.defAccept);
	}
	#end
}
