package;

#if lime
import lime.app.Event;
#end

/** Event-based "chaining" state machine. **/
class CSM // stands for Chaining State Machine
{
	#if lime
	/** Fires when the state has changed.**/
	public var onStateChanged(default, null) = new Event<String->Void>();
	#end

	/** The name of the current active state. **/
	public var currentState(default, set):String;

	/** Whether this state machine just changed states in the last frame. **/
	public var justChanged(default, null) = true;

	/** Whether this state machine has just received a change command during the current frame. **/
	private var _changedThisFrame = false;

	/** The list of defined states for this machine. **/
	private var _stateList:Map<String, Float->Void> = [];

	/** The list of global chain triggers for this state machine. **/
	private var _globalChainList:Map<String, String> = [];

	/** The list of chain triggers for this state machine. **/
	private var _chainList:Map<String, Map<String, String>> = [];

	/**
		Creates a new chaining state machine.
		@param initialState The function on which to start the state machine. It will always have the name "initial".
	**/
	public function new(initialState:Float->Void = null)
	{
		addState = _stateList.set;
		removeGlobal = _globalChainList.remove;

		currentState = "initial";
		_changedThisFrame = false;
		addState("initial", initialState);
	}

	function set_currentState(currentState)
	{
		#if lime
		onStateChanged.dispatch(currentState);
		#end

		_changedThisFrame = true;
		return this.currentState = currentState;
	}

	/**
		Calls the update function in this state machine, if any.
		@param update The time elapsed, in seconds, since the last `update` call.
	**/
	public function update(elapsed:Float)
	{
		if (currentState != null && _stateList.exists(currentState) && _stateList[currentState] != null)
			_stateList[currentState](elapsed);
		justChanged = _changedThisFrame;
		_changedThisFrame = false;
	}

	/**
		Add a state definition to the state library.
		@param name The name of the new state.
		@param func The function the state is tied to.
	**/
	public var addState(default, null):(String, Float->Void) -> Void;

	/**
		Set a chain association between two states.
		@param from The name of the state to chain from.
		@param trigger The trigger to act upon.
		@param to The name of the state to chain to.
		@return Whether the operation was successful.
	**/
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

	/**
		Sets a global trigger, which will fire if a local trigger does not exist.
		@param trigger The trigger to act upon.
		@param to The name of the state to chain to.
		@return Whether the operation was successful.
	**/
	public function setGlobal(trigger:String, to:String)
	{
		if (!_stateList.exists(to))
			return false;
		_globalChainList.set(trigger, to);
		return true;
	}

	/**
		Removes a chain association.
		@param from The name of the state to chain from.
		@param trigger Optional. The trigger to remove. If none is specified, removes all triggers.
		@return Whether the operation was successful.
	**/
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

	/**
		Removes a global trigger.
		@param trigger The trigger to remove.
		@return Whether the operation was successful.
	**/
	public var removeGlobal(default, null):String->Bool;

	/**
		Clears the state machine of all associations and defined states, except the "initial" state.
		@param initial Replace the initial state function with a new one.
	**/
	public function clear(initial:Float->Void = null)
	{
		if (initial == null)
			initial = _stateList["initial"];
		_stateList.clear();
		_stateList.set("initial", initial);
		_globalChainList.clear();
		return _chainList.clear();
	}

	/**
		Changes to a new state based on a given trigger.
		@param trigger The trigger to enact.
		@return Whether the operation was successful.
	**/
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
				trace('Trigger $trigger" not defined for $currentState');
			else
				trace('No trigger for $currentState');
			return false;
		}
	}

	/**
		Determines whether the current state name is the one provided.
		@param compare The state name to compare against.
		@return Whether the provided state name is the current active state.
	**/
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
