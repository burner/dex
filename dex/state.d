module dex.state;

import dex.strutil;
import dex.oldset;

import hurt.conv.conv;
import hurt.container.multimap;
import hurt.container.set;
import hurt.container.stack;
import hurt.container.vector;
import hurt.util.array;
import hurt.container.rbtree;

import std.stdio;

class State {
	int stateId;
	bool acceptingState;
	Set!(int) aStates;
	OldSet!(int) aStatesOld;
	MultiMap!(char,State) transition;
	Set!(State) nfaStates;

	this(int nId = -1) {
		this.stateId = nId;
		this.acceptingState = false;
		this.transition = new MultiMap!(char,State)();	
		this.nfaStates = new Set!(State)();
		this.aStates = new Set!(int)();
		this.aStatesOld = new OldSet!(int)();
	}

	this(int nId, Set!(State) NFAState) {
		this.stateId = nId;
		this.acceptingState = false;
		this.transition = new MultiMap!(char,State)();	
		this.nfaStates = NFAState.dup();
		this.aStates = new Set!(int)();
		this.aStatesOld = new OldSet!(int)();
		foreach(it;NFAState) {
			if(it.acceptingState) {
				foreach(jt;it.getAcceptingStates()) {
					this.setAcceptingState(jt);
				}	
			}
		}
	}

	bool compare(State toCmp) {
		if(this.acceptingState != toCmp.isAccepting()) {
			return false;
		}
		//assert(same(aStatesOld, aStates));	
		return this.aStates == toCmp.getAcceptingStates() &&
			this.transition == toCmp.getTransitions();
	}

	bool obEquals(Object o) const {
		State t = cast(State)o;
		return t.stateId == this.stateId;
	}

	hash_t toHash() const {
		return this.stateId;
	}

	int opCmp(Object o) const {
		State f = cast(State)o;
		if(this.toHash() < f.toHash())
			return 1;
		else if(this.toHash() > f.toHash())
			return -1;
		else
			return 0;
	}

	Set!(State) getNFAStates() {
		return this.nfaStates;
	}

	void setAcceptingState(int sId) {
		this.acceptingState = true;
		this.aStates.insert(sId);;	
		this.aStatesOld.insert(sId);;	
		assert(same(aStatesOld, aStates));	
	}

	Set!(int) getAcceptingStates() {
		assert(same(aStatesOld, aStates));	
		return this.aStates;
	}

	bool isAccepting() const {
		return this.acceptingState;
	}

	bool isDeadEnd() {
		assert(same(aStatesOld, aStates));	
		if(this.acceptingState)
			return false;
		if(this.transition.isEmpty())
			return true;
		foreach(it; this.transition.keys()) {
			//foreach(jt; this.transition.find(it)) {
			for(auto jt = this.transition.range(it); jt.isValid(); jt++) {
				if(this.stateId != (*jt).stateId) {
					return false;
				}
			}
		}
		return true;
	}

	int getStateId() {
		assert(same(aStatesOld, aStates));	
		return this.stateId;
	}

	MultiMap!(char,State) getTransitions() {
		assert(same(aStatesOld, aStates));	
		return this.transition;
	}	

	void addTransition(char chInput, State state) {
		assert(same(aStatesOld, aStates));	
		assert(state !is null);
		debug(StateDebug) writeln(__FILE__,__LINE__, " addTransition ", chInput , " ", state.stateId);
		size_t oldSize = this.transition.getSize();
		this.transition.insert(chInput, state);
		assert(oldSize != this.transition.getSize());
	}

	/*void overrideTransition(State old, State toReplaceWith) {
		auto it = this.transition.find(old);
		this.transition.replace(old, toReplaceWith);		
	}*/

	void removeTransition(State toRemove) {
		auto it = this.transition.begin();
		assert(same(aStatesOld, aStates));	
		while(it.isValid() && (*it) != toRemove) {
			it++;
		}
		if(it.isValid()) {
			size_t oldSize = this.transition.getSize();
			this.transition.remove(it);
			assert(oldSize != this.transition.getSize());
		}
	}
	
	State[] getTransition(char chInput) {
		assert(same(aStatesOld, aStates));	
		auto it = this.transition.range(chInput);	
		State[] ret = new State[10];
		size_t idx = 0;
		while(it.isValid()) {
			ret[idx++] = *it;
			if(idx == ret.length)
				ret.length = ret.length*2;
			it++;
		}
		return ret[0..idx];
	}

	State getSingleTransition(char chInput) {
		return *this.transition.begin();
	}

	string toString() {
		immutable deli = '_';
		immutable startStop = '\"';
		char[] tmp;
		size_t idx = 0;
		//assert(same(aStatesOld, aStates));	
		if(!this.aStates.isEmpty()) {
			tmp = new char[2+this.aStates.getSize()*3];
		} else {
			return "\"" ~ conv!(int,string)(this.stateId) ~ "\"";
		}
		appendWithIdx(tmp, idx++, startStop);
		
		string ut = conv!(int,string)(this.stateId);
		foreach(it; ut)
			tmp = appendWithIdx!(char)(tmp, idx++, it);

		foreach(it; this.aStates) {
			tmp = appendWithIdx!(char)(tmp, idx++, deli);
			string jt = conv!(int,string)(it);
			foreach(kt; jt)
				tmp = appendWithIdx!(char)(tmp, idx++, kt);
		}
		appendWithIdx(tmp, idx++, startStop);
		return tmp[0..idx].idup;
	}
}
