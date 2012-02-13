module dex.regex;

import dex.state;
import dex.strutil;
import dex.minimizer;
import dex.emit;

import hurt.container.dlst;
import hurt.container.isr;
import hurt.container.iterator;
import hurt.container.list;
import hurt.container.map;
import hurt.container.multimap;
import hurt.container.set;
import hurt.container.stack;
import hurt.container.vector;
import hurt.conv.conv;
import hurt.io.stdio;
import hurt.string.stringbuffer;
import hurt.time.stopwatch;
import hurt.util.array;
import hurt.util.slog;
import hurt.util.stacktrace;

public alias DLinkedList!(State) FSA_Table;
//public alias Deque!(State) FSA_Table;

/** All the logic from a multiple NFAs to a single NFA to a single DFA is
 *  is implemented in this file.
 */
class RegEx {
	private FSA_Table globalNfaTable;

	private FSA_Table nfaTable;
	private FSA_Table dfaTable;
	// private Deque!(State) dfaTable;
	private Stack!(FSA_Table) operandStack;
	private Stack!(dchar) operatorStack;

	private int nextStateId;
	private Set!(dchar) inputSet;
	private State rootState;
	private int patternIndex;
	private string strText;
	private Vector!(int) vecPos;
	private Vector!(State) minDfa;

	/// constructor
	this() {
		this.nfaTable = new FSA_Table();
		this.operandStack = new Stack!(FSA_Table)();
		this.operatorStack = new Stack!(dchar)();
		this.inputSet = new Set!(dchar);
		this.rootState = new State(nextStateId);
		this.globalNfaTable = new FSA_Table();
		this.globalNfaTable.pushBack(this.rootState);
	}

	/// prepare for the next nfa
	void cleanUp() {
		scope Trace st = new Trace("cleanUp");
		this.nfaTable = new FSA_Table();
		this.operandStack = new Stack!(FSA_Table)();
		this.operatorStack = new Stack!(dchar)();
	}

	/// create a nfa for the passed string and link it into the global nfa
	bool createNFA(string str, int action) {
		scope Trace st = new Trace("createNFA");
		this.cleanUp();
		//str = concatExpand(str);
		dstring pstr = concatExpand(conv!(string,dstring)(str));
		debug(RegExDebug) println(__FILE__,__LINE__, " ", pstr, " :length ",
			pstr.length);

		foreach(idx,it;pstr) {
			debug(RegExDebug) println(__FILE__,__LINE__, " ", it, " ", idx);
			if(isInput!(dchar)(it)) {
				debug(RegExDebug) println(__FILE__,__LINE__, " isInput");
				this.push(it);
			} else if(operatorStack.empty()) {
				debug(RegExDebug) println(__FILE__,__LINE__, 
					" operatorStack.empty");
				this.operatorStack.push(it);
			} else if(isLeftParanthesis!(dchar)(it)) {
				debug(RegExDebug) println(__FILE__,__LINE__, 
					" isLeftParanthesis");
				this.operatorStack.push(it);
			} else if(isRightParanthesis!(dchar)(it)) {
				debug(RegExDebug) println(__FILE__,__LINE__, 
					" isRightParanthesis");
				while(!isLeftParanthesis!(dchar)(this.operatorStack.top())) {
					if(!this.eval()) {
						return false;
					}
				}
				this.operatorStack.pop();
			} else {
				debug(RegExDebug) println(__FILE__,__LINE__, " else");
				while(!this.operatorStack.empty() && presedence!(dchar)(it, 
						this.operatorStack.top())) {
					debug(RegExDebug) println(__FILE__,__LINE__, " !(if.eval)");
					if(!this.eval()) {
						return false;
					}
				}
				debug(RegExDebug) println(__FILE__,__LINE__, 
					" operatorStack.push ", it);
				this.operatorStack.push(it);
			}
		}
		
		while(!operatorStack.empty()) {
			if(!this.eval()) {
				return false;
			}
		}

		// assign the operatorStack to the nfaTable
		if(!this.pop(this.nfaTable)) {
			return false;
		}

		this.nfaTable.get(this.nfaTable.getSize()).setAcceptingState(action);

		// save the current nfaTable to the globalNFATable. 
		// this is done to create a nfa
		// from more than one regex. to connect all regex join them 
		//through the rootState
		this.rootState.addTransition(0, this.nfaTable.get(0));
		//this.rootState.addTransition(0, this.nfaTable.front());
		foreach(it;this.nfaTable) {
			this.globalNfaTable.pushBack(it);
		}

		return true;
		
	}

	/// epsilon closure
	Set!(State) epsilonClosure(Set!(State) old) const {
		scope Trace st = new Trace("epsilonClosure");
		// Initialize result with old because each state
		// has epsilon closure to itself
		Set!(State) res = new Set!(State)(ISRType.HashTable);
		foreach(it; old) {
			res.insert(it);
		}

		// Push all states to be processes on the stack hence
		Stack!(State) unprocessedStack = new Stack!(State)(old.getSize()*2);
		foreach(it; old) {
			unprocessedStack.push(it);
		}

		// continue till there are no more events
		while(!unprocessedStack.empty()) {
			State t = unprocessedStack.pop();

			foreach(it; t.getTransition(0)) {
				if(!res.contains(it)) {
					res.insert(it);
					unprocessedStack.push(it);
				} else {
					State i = *res.find(it);
					foreach(jt; i.getAcceptingStates()) {
						i.setAcceptingState(jt);
					}
				}
			}
		}
		return res;	
	}

	/// move operation
	Set!(State) move(dchar chInput, Set!(State) t) const {
		scope Trace st = new Trace("move");
		Set!(State) res = new Set!(State)(ISRType.HashTable);
	
		/* This is very simple since I designed the NFA table
		   structure in a way that we just need to loop through
		   each state in T and recieve the transition on chInput.
		   Then we will put all the results into the set, which
		   will eliminate duplicates automatically for us. */
		foreach(iter; t) {
			State[] states = iter.getTransition(chInput);
			foreach(jter;states) {
				res.insert(jter);
			}
		}
		return res;
	}

	/// convert the global nfa to a single dfa
	void convertNfaToDfa() {
		scope Trace st = new Trace("convertNfaToDfa");
		//this.dfaTable = new Deque!(State)();
		this.dfaTable = new FSA_Table();
		if(this.globalNfaTable.getSize() == 0) {
			return;
		}

		// Reset the state id for new naming
		this.nextStateId = 0;

		// Vector of unprocessed DFA states
		Vector!(State) unmarkedStates = new Vector!(State)(32);

		// starting state of NFA state (set of states)
		Set!(State) NFAStartState = new Set!(State)();
		// the first state should have a stateId equal 0
		// otherwise something is wrong with the globalNfaTable
		assert(this.globalNfaTable.get(0).getStateId() == 0); 
		NFAStartState.insert(this.globalNfaTable.get(0));

		// Starting state of DFA is epsilon closure of 
		Set!(State) DFAStartStateSet = this.epsilonClosure(NFAStartState);

		// Create new DFA State (start state) from the NFA states
		State DFAStartState = new State(++nextStateId, DFAStartStateSet);

		// Add the start state to the DFA table because we should not lose it
		this.dfaTable.pushBack(DFAStartState);

		// Still need to process the state so add it to the unprocessed 
		//DFA state vector
		unmarkedStates.append(DFAStartState);
		
		int count = 0;	
		while(!unmarkedStates.empty()) {
			//println(count, " ",unmarkedStates.getSize()); count++;
			// process an unprocessed state
			State processingDFAState = unmarkedStates.popBack();

			// foreach input signal
			foreach(it;this.inputSet) {
				Set!(State) moveRes = this.move(it, 
					processingDFAState.getNFAStates());
				Set!(State) epsilonClosureRes = this.epsilonClosure(moveRes);
				
				// Check is the resulting set (EpsilonClosureSet) in the
				// set of DFA states (is any DFA state already constructed
				// from this set of NFA states) or in pseudocode:
				// is U in D-States already (U = EpsilonClosureSet)
				bool found = false;
				State s;
				foreach(jt; this.dfaTable) {
					s = jt;
					if(s.getNFAStates() == epsilonClosureRes) {
						found = true;
						break;
					}
				}
				
				if(!found) {
					State u = new State(++this.nextStateId, epsilonClosureRes);
					unmarkedStates.append(u);
					this.dfaTable.pushBack(u);

					// Add transition from processingDFAState to new state on 
					//the current character
					processingDFAState.addTransition(it, u);
				} else {
					// This state already exists so add transition from 
					// processingState to already processed state
					processingDFAState.addTransition(it, s);
				}
			}
		}
	}

	/* One state is never left, this is the error state.
	 * there should only be one. This states stateid will be set
	 * to -1. This is done so in the created scanner knows which
	 * state is the error state. */
	void findErrorState() {
		scope Trace st = new Trace("findErrorState");
		bool found = false;
		outer: foreach(ref it; this.dfaTable) {
			if(!it.isAccepting() && !it.getTransition().isEmpty()) {
				foreach(jt; it.getTransition().keys()) {
					//foreach(kt; it.transition.find(jt)) {
					for(auto kt = it.getTransition().range(jt); kt.isValid(); 
							kt++) {
						if(it.getStateId() != (*kt).getStateId()) {
							continue outer;	
						}
					}
				}
				if(found) {
					assert(0, "error a dfa can't have two error states");
				}
				found = true;
				it.setStateId(-1);
			}
		}
	}

	/// this removes the states with no outgoing states and no accepting states
	public static FSA_Table removeDeadStates(Iterable!(State) oldTable) {
		scope Trace st = new Trace("removeDeadStates");
		Map!(int,State) table = new Map!(int,State)(ISRType.HashTable);
		Set!(State) deadEndSet = new Set!(State)();
		foreach(it; oldTable) {
			if(it.isDeadEnd()) {
				deadEndSet.insert(it);
			} else {
				State tmp = new State(it.getStateId());
				auto accIt = it.getAcceptingStates().begin();
				for(; accIt.isValid(); accIt++)
					tmp.setAcceptingState(*accIt);

				table.insert(it.getStateId(),tmp);
			}
		}
		foreach(it; oldTable) {
			if(it.isDeadEnd())
				continue;
			State nIt = table.find(it.getStateId()).getData();
			auto tIt = it.getTransitions().begin();
			for(; tIt.isValid(); tIt++) {
				if(!deadEndSet.contains(*tIt)) {
					State tranState = table.find((*tIt).getStateId()).getData();
					assert(tranState !is null);
					nIt.addTransition(tIt.getKey, tranState);
				}
			}
		}
		FSA_Table ret = new FSA_Table();
		auto it = table.begin();
		for(; it.isValid(); it++)
			ret.pushBack((*it).getData());

		return ret;
	}

	/// push operation
	void push(dchar chInput) {
		scope Trace st = new Trace("push");
		State s0 = new State(++nextStateId);
		State s1 = new State(++nextStateId);
		s0.addTransition(chInput, s1);
		debug(RegExDebug) println(__FILE__,__LINE__, " after andTransition");

		FSA_Table table = new FSA_Table();
		table.pushBack(s0);
		table.pushBack(s1);
		debug(RegExDebug) println(__FILE__,__LINE__, " after table.push");

		this.operandStack.push(table);
		
		debug(RegExDebug) { println(__FILE__,__LINE__, " push operandStack");
			foreach(it;this.operandStack.values()) {
				foreach(jt;it) {
					write(jt.stateId, " ");
				}
				println();
			}
			println("\n");
		}

		this.inputSet.insert(chInput);
	}

	/// pop operation
	bool pop(ref FSA_Table table) {
		scope Trace st = new Trace("pop");
		debug(RegExDebug) println(__FILE__,__LINE__, " this.operandStack.size ",
			this.operandStack.getSize());
			
		if(this.operandStack.getSize() > 0) {
			table = operandStack.top();
			operandStack.pop();
			debug(RegExDebug) println(__FILE__,__LINE__, " nfaTable assigned");
			return true;
		}
		return false;
	}

	/// eval an expression
	bool eval() {
		scope Trace st = new Trace("eval");
		// First pop the operator from the stack
		debug(RegExDebug) println(__FILE__,__LINE__, 
			" eval this.operatorStack.size ", this.operatorStack.getSize());
		if(this.operatorStack.getSize()>0) {
			dchar chOperator = this.operatorStack.top();
			this.operatorStack.pop();
			debug(RegExDebug) println(__FILE__,__LINE__, " chOperator ", 
				chOperator);
	
			// Check which operator it is
			switch(chOperator) {
				//case '*':
				case ST:
					debug(RegExDebug) println(__FILE__,__LINE__, " star");
					return this.Star();
				//case '|':
				case UN:
					debug(RegExDebug) println(__FILE__,__LINE__, " union");
					return this.Union();
				//case '\a':
				case CC:
					debug(RegExDebug) println(__FILE__,__LINE__, " concat");
					return this.Concat();
				default:
					assert(0, "invalid case");
			}
		}
	
		return false;
	}

	/// concat operation
	bool Concat() {
		scope Trace st = new Trace("Concat");
		// Pop 2 elements
		FSA_Table A, B;
		if(!this.pop(B) || !this.pop(A))
			return false;

		debug(RegExDebug) println(__FILE__,__LINE__, " after pop");
	
		// Now evaluate AB
		// Basically take the last state from A
		// and add an epsilon transition to the
		// first state of B. Store the result into
		// new NFA_TABLE and push it onto the stack

		//A[A.size()-1].AddTransition(0, B[0]);
		assert(A !is null, "A shouldn't be null");
		assert(B !is null, "B shouldn't be null");
		A.get(A.getSize()).addTransition(0, B.get(0));
		//A.back().addTransition(0, B.front());
		debug(RegExDebug) println(__FILE__,__LINE__, " after A.get");
		foreach(it; B) {
			A.pushBack(it);
		}
	
		// Push the result onto the stack
		this.operandStack.push(A);
	
		return true;
	}
	
	/// star operation
	bool Star() {
		scope Trace st = new Trace("Star");
		// Pop 1 element
		FSA_Table A, B;
		if(!this.pop(A))
			return false;
	
		// Now evaluate A*
		// Create 2 new states which will be inserted 
		// at each end of deque. Also take A and make 
		// a epsilon transition from last to the first 
		// state in the queue. Add epsilon transition 
		// between two new states so that the one inserted 
		// at the begin will be the source and the one
		// inserted at the end will be the destination
		State pStartState = new State(++nextStateId);
		State pEndState	= new State(++nextStateId);
		pStartState.addTransition(0, pEndState);
	
		// add epsilon transition from start state to the first state of A
		pStartState.addTransition(0, A.get(0));
		//pStartState.addTransition(0, A.front());
	
		// add epsilon transition from A last state to end state
		A.get(A.getSize()).addTransition(0, pEndState);
		//A.back().addTransition(0, pEndState);
	
		// From A last to A first state
		A.get(A.getSize()).addTransition(0, A.get(0));
		//A.back().addTransition(0, A.front());

		// construct new DFA and store it onto the stack
		A.pushBack(pEndState);
		A.pushFront(pStartState);

		// Push the result onto the stack
		this.operandStack.push(A);

		return true;
	}

	/// union operation
	bool Union() {
		scope Trace st = new Trace("Union");
		// Pop 2 elements
		FSA_Table A, B;
		if(!this.pop(B) || !this.pop(A))
			return false;

		// Now evaluate A|B
		// Create 2 new states, a start state and
		// a end state. Create epsilon transition from
		// start state to the start states of A and B
		// Create epsilon transition from the end 
		// states of A and B to the new end state
		State pStartState = new State(++nextStateId);
		State pEndState	= new State(++nextStateId);
		pStartState.addTransition(0, A.get(0));
		pStartState.addTransition(0, B.get(0));
		//pStartState.addTransition(0, A.front());
		//pStartState.addTransition(0, B.front());
		A.get(A.getSize()).addTransition(0, pEndState);
		B.get(B.getSize()).addTransition(0, pEndState);
		//A.back().addTransition(0, pEndState);
		//B.back().addTransition(0, pEndState);
	
		// Create new NFA from A
		B.pushBack(pEndState);
		A.pushFront(pStartState);
		foreach(it; B) {
			A.pushBack(it);
		}
	
		// Push the result onto the stack
		this.operandStack.push(A);
	
		return true;
	}
		
	/// call the minimizer
	void minimize() {
		scope Trace st = new Trace("minimize");
		println("start to minimize with", this.dfaTable.getSize(), "states");
		this.minDfa = dex.minimizer.minimize!(dchar)(this.dfaTable, 
			this.inputSet);
		println("minimized to", this.minDfa.getSize(), "states");
	}

	/// write the minimized dfa graph
	void writeMinDFAGraph(string filename) {
		scope Trace st = new Trace("writeMinDFAGraph");
		auto tmp = removeDeadStates(this.minDfa);
		dex.emit.writeGraph(tmp,this.inputSet, filename);
	}

	/// write the dfa graph
	void writeDFAGraph(string filename) {
		scope Trace st = new Trace("writeDFAGraph");
		auto tmp = removeDeadStates(this.dfaTable);
		//dex.emit.writeGraph(this.dfaTable,this.inputSet, filename);
		dex.emit.writeGraph(tmp,this.inputSet, filename);
	}

	/// write the nfa graph
	void writeNFAGraph(string filename) {
		scope Trace st = new Trace("writeNFAGraph");
		auto tmp = removeDeadStates(this.globalNfaTable);
		dex.emit.writeGraph(tmp,this.inputSet, filename);
	}

	/// write the table for debugging
	void writeTable(string filename, MinTable min) {
		scope Trace st = new Trace("writeTable");
		dex.emit.writeTable(min, this.minDfa, this.inputSet, filename);
	}

	/// get the minimized table
	MinTable minTable() {
		scope Trace st = new Trace("minTable");
		println("table minimization started with", 
			this.minDfa.getSize() * this.inputSet.getSize(), "entries");
		MinTable ret = 	dex.minimizer.minTable(this.minDfa, this.inputSet);
		println("table minimized to", 
			ret.table[0].getSize() * ret.table.getSize(), "entries");
		return ret;
	}
}
