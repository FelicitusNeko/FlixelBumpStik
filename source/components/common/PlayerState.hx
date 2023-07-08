package components.common;

import boardObject.Launcher;
import boardObject.Bumper;
import lime.app.Event;

class PlayerState
{
	public var onScoreChanged(default, null) = new Event<Int->Void>();
	public var onBlockChanged(default, null) = new Event<Int->Void>();
	public var onLaunch(default, null) = new Event<Bumper->Void>();
	public var onNextChanged(default, null) = new Event<Bumper->Void>();

	public var score(default, set) = 0;
	public var block(default, set) = 0;
	public var next(default, set):Bumper = null;

	public function new() {}

	private function set_score(score)
	{
		onScoreChanged.dispatch(this.score = score);
		return this.score;
	}

	private function set_block(block)
	{
		onBlockChanged.dispatch(this.block = block);
		return this.block;
	}

	private function set_next(next)
	{
		onNextChanged.dispatch(this.next = next);
		return this.next;
	}

	public function launch(l:Launcher)
	{
		l.launchBumper(next);
		onLaunch.dispatch(next);
		next = null;
	}
}
