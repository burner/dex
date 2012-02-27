module dex.state;

import dex.strutil;

import hurt.container.isr;
import hurt.container.multimap;
import hurt.container.rbtree;
import hurt.container.set;
import hurt.container.stack;
import hurt.container.vector;
import hurt.conv.conv;
import hurt.string.utf;
import hurt.util.array;
import hurt.util.stacktrace;

/** The states of the nfa as well dfa graph structure is stored in this class.
 */
class State {
	private int stateId;
	private bool acceptingState;
	private Set!(int) aStates;
	private MultiMap!(dchar,State) transition;
	private Set!(State) nfaStates;

	/// default constructor
	this(int nId = -1) {
		this.stateId = nId;
		this.acceptingState = false;
		this.transition = new MultiMap!(dchar,State)(theType);	
		this.nfaStates = new Set!(State)(theType);
		this.aStates = new Set!(int)(theType);
	}

	/** Sort of copy constructor. Set theid and than copy the accepting states
	 *  of all the states in the set.
	 */
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

	/// Compare two states by their id
	public bool obEquals(Object o) const {
		State t = cast(State)o;
		return t.stateId == this.stateId;
	}

	/// Make a state placeable in a hashmap
	public override hash_t toHash() const {
		return this.stateId;
	}

	/// Make a state placeable in a tree
	public override int opCmp(Object o) const {
		State f = cast(State)o;
		if(this.toHash() < f.toHash())
			return 1;
		else if(this.toHash() > f.toHash())
			return -1;
		else
			return 0;
	}

	public Set!(State) getNFAStates() {
		return this.nfaStates;
	}

	public void setAcceptingState(in int sId) {
		this.acceptingState = true;
		this.aStates.insert(sId);
	}

	public int getFirstAcceptingState() {
		return *this.aStates.begin();
	}

	public Set!(int) getAcceptingStates() {
		return this.aStates;
	}

	public bool isAccepting() const {
		return this.acceptingState;
	}

	/// check if the state has no outgoing transition and is not accepting
	public bool isDeadEnd() {
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

	public int getStateId() const {
		return this.stateId;
	}

	public void setStateId(in int id) {
		this.stateId = id;
	}

	public MultiMap!(dchar,State) getTransitions() {
		return this.transition;
	}	

	/// add a transition to the state
	public void addTransition(dchar chInput, State state) {
		if(state is null) {
			Trace.printTrace();
			assert(false);
		}
		debug(StateDebug) writeln(__FILE__,__LINE__, 
			" addTransition ", chInput , " ", state.stateId);
		size_t oldSize = this.transition.getSize();
		this.transition.insert(chInput, state);
		assert(oldSize != this.transition.getSize());
	}

	/// remove a transition from the state
	public void removeTransition(State toRemove) {
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

	public MultiMap!(dchar,State) getTransition() {
		return this.transition;
	}

	public Iterator!(dchar,State) getTransitionIt(dchar chInput) {
		return this.transition.range(chInput);
	}
	
	/// get all States for given character
	public State[] getTransition(dchar chInput) {
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

	/// get a single state for given character. This is for DFAs
	public State getSingleTransition(dchar chInput) {
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
