module dex.state;

import dex.multimap;
import dex.set;
import dex.util;

import hurt.container.stack;
import hurt.container.vector;

import std.stdio;

class State {
	int stateId;
	bool acceptingState;
	MultiMap!(char,State) transition;
	Set!(State) nfaStates;

	this(int nId = -1) {
		this.stateId = nId;
		this.acceptingState = false;
		this.transition = new MultiMap!(char,State)();	
		this.nfaStates = new Set!(State)();
	}

	this(int nId, Set!(State) NFAState) {
		this.stateId = nId;
		this.acceptingState = false;
		this.transition = new MultiMap!(char,State)();	
		this.nfaStates = NFAState.dup();
		foreach(it;NFAState.values()) {
			if(it.acceptingState) {
				this.acceptingState = true;
				break;
			}
		}
	}

	bool obEquals(Object o) {
		if(is(o == State)) {
			State t = cast(State)o;
			return t.stateId == this.stateId;
		}
		return false;
	}

	hash_t toHash() {
		return this.stateId;
	}

	int opCmp(Object o) {
		State f = cast(State)o;
		if(!f)
			
	}

	void addTransition(char chInput, State state) {
		assert(state !is null);
		debug(StateDebug) writeln(__FILE__,__LINE__, " addTransition ", chInput , " ", state.stateId);
		transition.insert(chInput, state);
	}
	
	State[] getTransition(char chInput) {
		State[] ret = this.transition.find(chInput);	
		return ret;
	}
}
