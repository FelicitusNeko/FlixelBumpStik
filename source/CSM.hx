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

	/** The list of chain triggers for this state machine. **/
	private var _chainList:Map<String, Map<String, String>> = [];

	public function new(initialState:Float->Void = null)
	{
		addState("initial", initialState);
		currentState = "initial";
	}

	function set_currentState(currentState)
	{
		_changedThisFrame = true;
		return this.currentState = currentState;
	}

	public function addState(name:String, func:Float->Void)
	{
		return _stateList.set(name, func);
	}

	/** Calls the update function in this state machine, if any. **/
	public function update(elapsed:Float)
	{
		if (currentState != null && _stateList.exists(currentState) && _stateList[currentState] != null)
			_stateList[currentState](elapsed);
		justChanged = _changedThisFrame;
		_changedThisFrame = false;
	}

	public function set(from:String, trigger:String, to:String)
	{
		var fromStr = Std.string(from);
		if (_chainList.exists(fromStr))
			return _chainList[fromStr].set(trigger, to);
		else
			return _chainList.set(fromStr, [trigger => to]);
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

	public function clear()
	{
		return _chainList.clear();
	}

	public function chain(trigger:String)
	{
		if (!_chainList.exists(currentState))
		{
			trace("No trigger for " + currentState);
			return false;
		}
		else if (!_chainList[currentState].exists(trigger))
		{
			trace("Trigger " + trigger + " not defined for " + currentState);
			return false;
		}
		else
		{
			currentState = _chainList[currentState][trigger];
			return true;
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
