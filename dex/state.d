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
		if(is(o : State)) {
			State f = cast(State)o;
			size_t fHash = f.toHash();
			size_t thisHash = this.toHash();
			if(thisHash > fHash)
				return 1;
			else if(thisHash < fHash)
				return -1;
			else
				return 0;
		}
		return 1;
	}

	Set!(State) getNFAStates() {
		return this.nfaStates;
	}

	bool isDeadEnd() {
		if(this.acceptingState)
			return false;
		if(this.transition.empty())
			return true;
		foreach(it; this.transition.keys()) {
			foreach(jt; this.transition.find(it)) {
				if(this.stateId != jt.stateId) {
					return false;
				}
			}
		}
		return true;
	}

	void addTransition(char chInput, State state) {
		assert(state !is null);
		debug(StateDebug) writeln(__FILE__,__LINE__, " addTransition ", chInput , " ", state.stateId);
		transition.insert(chInput, state);
	}

	void removeTransition(State toRemove) {
		this.transition.remove(toRemove);
	}
	
	State[] getTransition(char chInput) {
		State[] ret = this.transition.find(chInput);	
		return ret;
	}
}
