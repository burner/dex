module dex.fsm;

import dex.bitmap;

class State {
	// these are used to make the map
	private State[] next;		
	private BitMap allowed;

	// the char this State represents
	private dchar state;

	public this(dchar state) {
		this.state = state;
		this.allowed = new BitMap();
	}
}

class Machine {
	//private DLinkedList!(State) allStates;

	this() {
	//	this.allStates = new DLinkedList!(State)();
	}
}
