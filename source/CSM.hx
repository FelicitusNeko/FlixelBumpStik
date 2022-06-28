package;

/** Event-based "chaining" state machine. **/
class CSM
{
	public var currentState(default, set):String;

	private var _stateList:Map<String, Float->Void> = [];

	/** Whether this state machine just changed states in the last frame. **/
	public var justChanged(default, null) = true;

	/** Whether this state machine has just received a change command during the current frame. **/
	private var _changedThisFrame = true;

	/** The list of global chain triggers for this state machine. **/
	private var _globalChainList:Map<String, String> = [];

	/** The list of chain triggers for this state machine. **/
	private var _chainList:Map<String, Map<String, String>> = [];

	public function new(initialState:Float->Void = null)
	{
		addState("initial", initialState);
		currentState = "initial";
		addState = _stateList.set;
		removeGlobal = _globalChainList.remove;
	}

	function set_currentState(currentState)
	{
		_changedThisFrame = true;
		return this.currentState = currentState;
	}

	// public function addState(name:String, func:Float->Void)
	// {
	// 	return _stateList.set(name, func);
	// }

	/** Calls the update function in this state machine, if any. **/
	public function update(elapsed:Float)
	{
		if (currentState != null && _stateList.exists(currentState) && _stateList[currentState] != null)
			_stateList[currentState](elapsed);
		justChanged = _changedThisFrame;
		_changedThisFrame = false;
	}

	public var addState(default, null):(String, Float->Void) -> Void;

	public function set(from:String, trigger:String, to:String)
	{
		if (!_stateList.exists(to))
			return false;
		if (_chainList.exists(from))
			_chainList[from].set(trigger, to);
		else
			_chainList.set(from, [trigger => to]);
		return true;
	}

	public function setGlobal(trigger:String, to:String)
	{
		if (!_stateList.exists(to))
			return false;
		_globalChainList.set(trigger, to);
		return true;
	}

	public function remove(from:Float->Void, ?trigger:String)
	{
		var fromStr = Std.string(from);
		if (trigger == null)
			return _chainList.remove(fromStr);
		else if (_chainList.exists(fromStr))
			return _chainList[fromStr].remove(trigger);
		else
			return false;
	}

	public var removeGlobal(default, null):String->Void;

	public function clear()
	{
		var initial = _stateList["initial"];
		_stateList.clear();
		_stateList.set("initial", initial);
		_globalChainList.clear();
		return _chainList.clear();
	}

	public function chain(trigger:String)
	{
		if (_chainList.exists(currentState) && _chainList[currentState].exists(trigger))
		{
			currentState = _chainList[currentState][trigger];
			return true;
		}
		else if (_globalChainList.exists(trigger))
		{
			currentState = _globalChainList[trigger];
			return true;
		}
		else
		{
			if (_chainList.exists(currentState))
				trace("Trigger " + trigger + " not defined for " + currentState);
			else
				trace("No trigger for " + currentState);
			return false;
		}
	}

	public function is(compare:String)
	{
		return currentState == compare;
	}

	/**
		Determines whether the current stored state function is the one provided.
		@param compare The state function to compare against.
		@return Whether the provided state function (or lack thereof) is the current active function.
	**/
	public function isFunc(compare:Null<Float->Void>)
	{
		return _stateList.exists(currentState) && _stateList[currentState] == compare;
	}
}
