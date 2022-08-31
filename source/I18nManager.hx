package;

import haxe.Exception;
import jsoni18n.I18n;
import openfl.utils.Assets;

class I18nManager
{
	public static var defaultLang = "en-US";

	private var _i18n = new I18n();

	public var lang(default, set):String;

	public var tr(default, null):(String, ?Map<String, Dynamic>) -> String;

	public function new(?lang:String)
	{
		tr = _i18n.tr;
		this.lang = lang == null ? defaultLang : lang;
	}

	private function set_lang(lang:String)
	{
		if (!Assets.exists('assets/i18n/$defaultLang.json'))
			throw new Exception('Default language file $defaultLang.json not found');
		if (lang != defaultLang && !Assets.exists('assets/i18n/$lang.json'))
			throw new Exception('Language file $lang.json not found');

		_i18n.clear();
		_i18n.loadFromString(Assets.getText('assets/i18n/$defaultLang.json'));
		if (lang != defaultLang)
			_i18n.loadFromString(Assets.getText('assets/i18n/$lang.json'));
		return this.lang = lang;
	}
}
