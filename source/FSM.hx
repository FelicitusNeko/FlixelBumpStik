package;

/**
	This finite state machine helps with code management among different game states.
**/
class FSM
{
	public var activeState:Null<Float->Void>;

	public function new(initialState:Null<Float->Void> = null)
	{
		activeState = initialState;
	}

	public function update(elapsed:Float)
	{
		if (activeState != null)
			activeState(elapsed);
	}

	public function is(compare:Null<Float->Void>)
	{
		return activeState == compare;
	}
}
