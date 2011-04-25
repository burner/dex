module dex.state;

import dex.strutil;

import hurt.conv.conv;
import hurt.container.multimap;
import hurt.container.set;
import hurt.container.stack;
import hurt.container.vector;
import hurt.util.array;

import std.stdio;

class State {
	int stateId;
	bool acceptingState;
	int[] aStates;
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
				foreach(jt;it.getAcceptingStates()) {
					this.setAcceptingState(jt);
				}	
			}
		}
	}

	bool compare(State toCmp) {

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

	void setAcceptingState(int sId) {
		this.acceptingState = true;
		if(this.aStates !is null) {
			foreach(it; this.aStates) {
				if(it == sId) {
					return;
				}
			}
		}
		append(this.aStates, sId);	
	}

	int[] getAcceptingStates() {
		return this.aStates;
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

	int getStateId() {
		return this.stateId;
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

	string toString() const {
		immutable deli = '_';
		immutable startStop = '\"';
		char[] tmp;
		size_t idx = 0;
		if(this.aStates !is null) {
			tmp = new char[2+this.aStates.length*3];
		} else {
			return "\"" ~ conv!(int,string)(this.stateId) ~ "\"";
		}
		appendWithIdx(tmp, idx++, startStop);
		
		string ut = conv!(int,string)(this.stateId);
		foreach(it; ut)
			tmp = appendWithIdx!(char)(tmp, idx++, it);


		foreach(it;this.aStates) {
			tmp = appendWithIdx!(char)(tmp, idx++, deli);
			string jt = conv!(int,string)(it);
			foreach(kt; jt)
				tmp = appendWithIdx!(char)(tmp, idx++, kt);
		}
		appendWithIdx(tmp, idx++, startStop);
		return tmp[0..idx].idup;
	}
}
