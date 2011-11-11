module dex.state;

import dex.strutil;

import hurt.conv.conv;
import hurt.container.multimap;
import hurt.container.isr;
import hurt.container.set;
import hurt.container.stack;
import hurt.container.vector;
import hurt.util.array;
import hurt.util.stacktrace;
import hurt.container.rbtree;
import hurt.string.utf;

import std.stdio;

class State {
	int stateId;
	bool acceptingState;
	Set!(int) aStates;
	MultiMap!(dchar,State) transition;
	Set!(State) nfaStates;

	this(int nId = -1) {
		this.stateId = nId;
		this.acceptingState = false;
		this.transition = new MultiMap!(dchar,State)();	
		this.nfaStates = new Set!(State)();
		this.aStates = new Set!(int)();
	}

	this(int nId, Set!(State) NFAState) {
		this(nId);
		this.nfaStates = NFAState.dup();
		foreach(it;NFAState) {
			if(it.acceptingState) {
				foreach(jt;it.getAcceptingStates()) {
					this.setAcceptingState(jt);
				}	
			}
		}
	}

	public bool obEquals(Object o) const {
		State t = cast(State)o;
		return t.stateId == this.stateId;
	}

	public override hash_t toHash() const {
		return this.stateId;
	}

	public override int opCmp(Object o) const {
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

	void setAcceptingState(in int sId) {
		this.acceptingState = true;
		this.aStates.insert(sId);;	
	}

	int getFirstAcceptingState() {
		return *this.aStates.begin();
	}

	Set!(int) getAcceptingStates() {
		return this.aStates;
	}

	bool isAccepting() const {
		return this.acceptingState;
	}

	bool isDeadEnd() {
		scope Trace st = new Trace("isDeadEnd");
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

	int getStateId() const {
		return this.stateId;
	}

	void setStateId(in int id) {
		this.stateId = id;
	}

	MultiMap!(dchar,State) getTransitions() {
		return this.transition;
	}	

	void addTransition(dchar chInput, State state) {
		assert(state !is null);
		debug(StateDebug) writeln(__FILE__,__LINE__, 
			" addTransition ", chInput , " ", state.stateId);
		size_t oldSize = this.transition.getSize();
		this.transition.insert(chInput, state);
		assert(oldSize != this.transition.getSize());
	}

	void removeTransition(State toRemove) {
		auto it = this.transition.begin();
		while(it.isValid() && (*it) != toRemove) {
			it++;
		}
		if(it.isValid()) {
			size_t oldSize = this.transition.getSize();
			this.transition.remove(it);
			assert(oldSize != this.transition.getSize());
		}
	}
	
	State[] getTransition(dchar chInput) {
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

	State getSingleTransition(dchar chInput) {
		Iterator!(dchar,State) it = this.transition.range(chInput);
		return it.isValid() ? *it : null;
	}

	public override string toString() {
		immutable dchar deli = '_';
		immutable dchar startStop = '\"';
		dchar[] tmp;
		size_t idx = 0;
		//assert(same(aStatesOld, aStates));	
		if(!this.aStates.isEmpty()) {
			tmp = new dchar[2+this.aStates.getSize()*3];
		} else {
			return "\"" ~ conv!(int,string)(this.stateId) ~ "\"";
		}
		appendWithIdx(tmp, idx++, startStop);
		
		dstring ut = conv!(int,dstring)(this.stateId);
		foreach(it; ut)
			tmp = appendWithIdx!(dchar)(tmp, idx++, it);

		foreach(it; this.aStates) {
			tmp = appendWithIdx!(dchar)(tmp, idx++, deli);
			dstring jt = conv!(int,dstring)(it);
			foreach(kt; jt)
				tmp = appendWithIdx!(dchar)(tmp, idx++, kt);
		}
		appendWithIdx(tmp, idx++, startStop);
		return toUTF8(tmp[0..idx]).idup;
	}
}
