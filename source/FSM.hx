package;

/**
	This finite state machine helps with code management among different game states.
**/
class FSM
{
	/** The current active state for this state machine. **/
	public var activeState(default, set):Null<Float->Void>;

	/** Whether this state machine just changed states in the last frame. **/
	public var justChanged(default, null) = true;

	/** Whether this state machine has just received a change command during the current frame. **/
	private var _justChanging = true;

	public function new(initialState:Null<Float->Void> = null)
	{
		activeState = initialState;
	}

	function set_activeState(activeState:Null<Float->Void>):Null<Float->Void>
	{
		// trace("state change");
		_justChanging = true;
		return this.activeState = activeState;
	}

	/** Calls the update function in this state machine, if any. **/
	public function update(elapsed:Float)
	{
		// if (justChanged)
		// 	trace("calling new state for first frame");
		if (activeState != null)
			activeState(elapsed);
		justChanged = _justChanging;
		_justChanging = false;
	}

	/**
		Determines whether the current stored state function is the one provided.
		@param compare The state function to compare against.
		@return Whether the provided state function (or lack thereof) is the current active function.
	**/
	public function is(compare:Null<Float->Void>)
	{
		return activeState == compare;
	}
}
