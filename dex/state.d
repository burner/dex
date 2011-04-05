module dex.state;

import dex.multimap;
import dex.set;
import dex.util;

import hurt.container.stack;

class State {
	MultiMap!(char,State) mTransition;	
	Set!(State) mNFAStates;

	int stateId;
	bool acceptingState;

	this(int nId = -1) {
		this.stateId = nId;
		this.acceptingState = false;
	}

	this(int nId, Set!(State) NFAState) {
		this.stateId = nId;
	
	}

	bool obEquals(Object o) {
		if(is(o == State)) {
			State t = cast(State)o;
			return t.stateId == this.stateId;
		}
		return false;
	}

	bool createNFA(string str) {
		str = concatExpand!(char)(str);
		char c;
		foreach(idx,it;str) {
			if(isInput(c)) {
				this.push(c);
			} else if(
		}
		return true;
	}

}

