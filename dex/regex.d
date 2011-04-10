module dex.regex;

import dex.state;
import dex.list;
import dex.set;
import dex.patternstate;
import dex.util;
import dex.multimap;

import hurt.conv.conv;
import hurt.container.dlst;
import hurt.container.stack;
import hurt.container.vector;
import hurt.util.stacktrace;
import hurt.util.array;
import hurt.string.stringbuffer;

import std.stdio;
import std.stream;
import std.process;

alias DLinkedList!(State) FSA_Table;

class RegEx {
	FSA_Table globalNfaTable;

	FSA_Table nfaTable;
	FSA_Table dfaTable;
	Stack!(FSA_Table) operandStack;
	Stack!(char) operatorStack;

	int nextStateId;

	Set!(char) inputSet;

	List!(PatternState) patternList;

	State rootState;

	int patternIndex;

	string strText;

	Vector!(int) vecPos;

	this() {
		this.nfaTable = new FSA_Table();
		this.operandStack = new Stack!(FSA_Table)();
		this.operatorStack = new Stack!(char)();
		this.inputSet = new Set!(char);
		this.patternList = new List!(PatternState)();
		this.rootState = new State(nextStateId);
		this.globalNfaTable = new FSA_Table();
		this.globalNfaTable.pushBack(this.rootState);
	}

	void cleanUp() {
		this.nfaTable = new FSA_Table();
		this.operandStack = new Stack!(FSA_Table)();
		this.operatorStack = new Stack!(char)();
		this.patternList = new List!(PatternState)();
	}

	bool createNFA(string str) {
		str = concatExpand(str);
		writeln(__FILE__,__LINE__, " ", str, " :length ",str.length);
			
		foreach(idx,it;str) {
			debug(RegExDebug) writeln(__FILE__,__LINE__, " ", it, " ", idx);
			if(isInput!(char)(it)) {
				debug(RegExDebug) writeln(__FILE__,__LINE__, " isInput");
				this.push(it);
			} else if(operatorStack.empty()) {
				debug(RegExDebug) writeln(__FILE__,__LINE__, " operatorStack.empty");
				this.operatorStack.push(it);
			} else if(isLeftParanthesis!(char)(it)) {
				debug(RegExDebug) writeln(__FILE__,__LINE__, " isLeftParanthesis");
				this.operatorStack.push(it);
			} else if(isRightParanthesis!(char)(it)) {
				debug(RegExDebug) writeln(__FILE__,__LINE__, " isRightParanthesis");
				while(!isLeftParanthesis!(char)(this.operatorStack.top())) {
					if(!this.eval()) {
						return false;
					}
				}
				this.operatorStack.pop();
			} else {
				debug(RegExDebug) writeln(__FILE__,__LINE__, " else");
				while(!this.operatorStack.empty() && presedence!(char)(it, this.operatorStack.top())) {
					debug(RegExDebug) writeln(__FILE__,__LINE__, " !(if.eval)");
					if(!this.eval()) {
						return false;
					}
				}
				debug(RegExDebug) writeln(__FILE__,__LINE__, " operatorStack.push ", it);
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

		//this.nfaTable.get(this.nfaTable.getSize() - 1u).acceptingState = true;
		this.nfaTable.get(this.nfaTable.getSize()).acceptingState = true;

		// save the current nfaTable to the globalNFATable. this is done to create a nfa
		// from more than one regex. to connect all regex join them through the rootState
		this.rootState.addTransition(0, this.nfaTable.get(0));
		foreach(it;this.nfaTable) {
			this.globalNfaTable.pushBack(it);
		}

		return true;
		
	}

	Set!(State) epsilonClosure(Set!(State) old) const {
		// Initialize result with old because each state
		// has epsilon closure to itself
		Set!(State) res = new Set!(State)(old);

		// Push all states to be processes on the stack hence
		Stack!(State) unprocessedStack = new Stack!(State)();
		foreach(it; old.values()) {
			unprocessedStack.push(it);
		}

		// continue till there are no more events
		while(!unprocessedStack.empty()) {
			State t = unprocessedStack.pop();

			foreach(it; t.getTransition(0)) {
				if(!res.contains(it)) {
					res.insert(it);
					unprocessedStack.push(it);
				}
			}
		}
		return res;	
	}

	Set!(State) move(char chInput, Set!(State) t) const {
		Set!(State) res = new Set!(State)();
	
		/* This is very simple since I designed the NFA table
		   structure in a way that we just need to loop through
		   each state in T and recieve the transition on chInput.
		   Then we will put all the results into the set, which
		   will eliminate duplicates automatically for us. */
		foreach(iter; t.values()) {
			State[] states = iter.getTransition(chInput);
			foreach(jter;states) {
				res.insert(jter);
			}
		}
		return res;
	}

	void convertNfaToDfa() {
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
		assert(this.globalNfaTable.get(0).stateId == 0); 
		NFAStartState.insert(this.globalNfaTable.get(0));

		// Starting state of DFA is epsilon closure of 
		Set!(State) DFAStartStateSet = this.epsilonClosure(NFAStartState);

		// Create new DFA State (start state) from the NFA states
		State DFAStartState = new State(++nextStateId, DFAStartStateSet);

		// Add the start state to the DFA table because we should not lose it
		this.dfaTable.pushBack(DFAStartState);

		// Still need to process the state so add it to the unprocessed DFA state vector
		unmarkedStates.append(DFAStartState);
		
		while(!unmarkedStates.empty()) {
			// process an unprocessed state
			State processingDFAState = unmarkedStates.popBack();

			// foreach input signal
			foreach(it;this.inputSet.values()) {
				Set!(State) moveRes = this.move(it, processingDFAState.getNFAStates());
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

					// Add transition from processingDFAState to new state on the current character
					processingDFAState.addTransition(it, u);
				} else {
					// This state already exists so add transition from 
					// processingState to already processed state
					processingDFAState.addTransition(it, s);
				}
			}
		}
		this.findErrorState();
	}

	/* One state is never left, this is the error state.
	 * there should only be one. This states stateid will be set
	 * to -1. This is done so in the created scanner knows which
	 * state is the error state. */
	void findErrorState() {
		bool found = false;
		outer: foreach(it; this.dfaTable) {
			if(!it.acceptingState && !it.transition.empty()) {
				foreach(jt; it.transition.keys()) {
					foreach(kt; it.transition.find(jt)) {
						if(it.stateId != kt.stateId) {
							continue outer;	
						}
					}
				}
				if(found) {
					assert(0, "error a dfa can't have to error states");
				}
				found = true;
				it.stateId = -1;
			}
		}
	}

	void removeDeadStates() {

	}

	void push(char chInput) {
		debug scope StackTrace st = new StackTrace(__FILE__, __LINE__,
			"push");
		debug st.putArgs("char", "chInput", chInput);
			
		State s0 = new State(++nextStateId);
		State s1 = new State(++nextStateId);
		s0.addTransition(chInput, s1);
		debug(RegExDebug) writeln(__FILE__,__LINE__, " after andTransition");

		FSA_Table table = new FSA_Table();
		table.pushBack(s0);
		table.pushBack(s1);
		debug(RegExDebug) writeln(__FILE__,__LINE__, " after table.push");

		this.operandStack.push(table);
		
		debug(RegExDebug) { writeln(__FILE__,__LINE__, " push operandStack");
			foreach(it;this.operandStack.values()) {
				foreach(jt;it) {
					write(jt.stateId, " ");
				}
				writeln();
			}
			writeln("\n");
		}
			

		this.inputSet.insert(chInput);
	}

	bool pop(ref FSA_Table table) {
		debug scope StackTrace st = new StackTrace(__FILE__, __LINE__,
			"pop");

		debug(RegExDebug) writeln(__FILE__,__LINE__, " this.operandStack.size ", this.operandStack.getSize());
			
		if(this.operandStack.getSize() > 0) {
			table = operandStack.top();
			operandStack.pop();
			debug(RegExDebug) writeln(__FILE__,__LINE__, " nfaTable assigned");
			return true;
		}
		return false;
	}

	bool eval() {
		debug scope StackTrace st = new StackTrace(__FILE__, __LINE__,
			"eval");

		// First pop the operator from the stack
		debug(RegExDebug) writeln(__FILE__,__LINE__, " eval this.operatorStack.size ", this.operatorStack.getSize());
		if(this.operatorStack.getSize()>0) {
			char chOperator = this.operatorStack.top();
			this.operatorStack.pop();
			debug(RegExDebug) writeln(__FILE__,__LINE__, " chOperator ", chOperator);
	
			// Check which operator it is
			switch(chOperator) {
				case  '*':
					debug(RegExDebug) writeln(__FILE__,__LINE__, " star");
					return this.Star();
				case '|':
					debug(RegExDebug) writeln(__FILE__,__LINE__, " union");
					return this.Union();
				case '\a':
					debug(RegExDebug) writeln(__FILE__,__LINE__, " concat");
					return this.Concat();
			}
	
			return false;
		}
	
		return false;
	}

	bool Concat() {
		debug scope StackTrace st = new StackTrace(__FILE__, __LINE__,
			"Concat");
		// Pop 2 elements
		FSA_Table A, B;
		if(!this.pop(B) || !this.pop(A))
			return false;

		debug(RegExDebug) writeln(__FILE__,__LINE__, " after pop");
	
		// Now evaluate AB
		// Basically take the last state from A
		// and add an epsilon transition to the
		// first state of B. Store the result into
		// new NFA_TABLE and push it onto the stack

		//A[A.size()-1].AddTransition(0, B[0]);
		assert(A !is null, "A shouldn't be null");
		assert(B !is null, "B shouldn't be null");
		//A.get(A.getSize()-1).addTransition(0, B.get(0));
		A.get(A.getSize()).addTransition(0, B.get(0));
		debug(RegExDebug) writeln(__FILE__,__LINE__, " after A.get");
		//A.insert(A.end(), B.begin(), B.end());
		foreach(it; B) {
			A.pushBack(it);
		}
	
		// Push the result onto the stack
		this.operandStack.push(A);
	
		return true;
	}
	
	bool Star() {
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
		//pStartState.addTransition(0, A[0]);
		pStartState.addTransition(0, A.get(0));
	
		// add epsilon transition from A last state to end state
		//A[A.size()-1]->AddTransition(0, pEndState);
		A.get(A.getSize()).addTransition(0, pEndState);
	
		// From A last to A first state
		//A[A.size()-1]->AddTransition(0, A[0]);
		A.get(A.getSize()).addTransition(0, A.get(0));

		// construct new DFA and store it onto the stack
		A.pushBack(pEndState);
		A.pushFront(pStartState);

		// Push the result onto the stack
		this.operandStack.push(A);

		return true;
	}

	bool Union() {
		debug scope StackTrace st = new StackTrace(__FILE__, __LINE__,
			"Union");
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
		//pStartState.addTransition(0, A[0]);
		//pStartState.addTransition(0, B[0]);
		pStartState.addTransition(0, A.get(0));
		pStartState.addTransition(0, B.get(0));
		//A[A.size()-1]->AddTransition(0, pEndState);
		//B[B.size()-1]->AddTransition(0, pEndState);
		A.get(A.getSize()).addTransition(0, pEndState);
		B.get(B.getSize()).addTransition(0, pEndState);
	
		// Create new NFA from A
		B.pushBack(pEndState);
		A.pushFront(pStartState);
		//A.insert(A.end(), B.begin(), B.end()); TODO
		foreach(it; B) {
			A.pushBack(it);
		}
	
		// Push the result onto the stack
		this.operandStack.push(A);
	
		return true;
	}

	void writeNFATable() {
		string[] strNFATable;
		StringBuffer!(char) strNFALine = new StringBuffer!(char)(16);
		foreach(it; this.inputSet.values()) {
			strNFALine.pushBack("\t\t").pushBack(it);
		}
		strNFALine.pushBack('\t').pushBack('\t').pushBack("epsilon");
		append(strNFATable, strNFALine.getString());
		strNFALine.clear();

	}

	void writeDFAGraph() {
		string[] strNFATable = ["digraph{\n"];
		StringBuffer!(char) strNFALine = new StringBuffer!(char)(16);
		foreach(it;this.dfaTable) {
			if(it.acceptingState) {
				strNFALine.pushBack('\t').pushBack(conv!(int,string)(it.stateId));
				strNFALine.pushBack("\t[shape=doublecircle];\n");
				append(strNFATable, strNFALine.getString());
				strNFALine.clear();
			}
		}
		append(strNFATable, "\n");
		strNFALine.clear();

		// Record transitions
		foreach(pState;this.dfaTable) {
			State[] state = pState.getTransition(0);	

			// Record transition
			foreach(jt;state) {
				string stateId1 = conv!(int,string)(pState.stateId);
				string stateId2 = conv!(int,string)(jt.stateId);
				strNFALine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
				strNFALine.pushBack("\t[label=\"epsilon\"];\n");
				append(strNFATable, strNFALine.getString());
				strNFALine.clear();
			}

			foreach(jt;this.inputSet.values()) {
				state = pState.getTransition(jt);
				foreach(kt;state) {
					string stateId1 = conv!(int,string)(pState.stateId);
					string stateId2 = conv!(int,string)(kt.stateId);
					strNFALine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
					strNFALine.pushBack("\t[label=\"" ~ jt ~ "\"];\n");
					append(strNFATable, strNFALine.getString());
					strNFALine.clear();
				}
			}	
			
		}

		append(strNFATable, "}");
		std.stream.File file = new std.stream.File("dfaGraph.dot", FileMode.OutNew);
		foreach(it;strNFATable) {
			file.writeString(it);
		}
		file.close();
		system("dot -T jpg dfaGraph.dot > dfaGraph.jpg");
	}

	void writeNFAGraph() {
		string[] strNFATable = ["digraph{\n"];
		StringBuffer!(char) strNFALine = new StringBuffer!(char)(16);
		foreach(it;this.globalNfaTable) {
			if(it.acceptingState) {
				strNFALine.pushBack('\t').pushBack(conv!(int,string)(it.stateId));
				strNFALine.pushBack("\t[shape=doublecircle];\n");
				append(strNFATable, strNFALine.getString());
				strNFALine.clear();
			}
		}
		append(strNFATable, "\n");
		strNFALine.clear();

		// Record transitions
		foreach(pState;this.globalNfaTable) {
			State[] state = pState.getTransition(0);	

			// Record transition
			foreach(jt;state) {
				string stateId1 = conv!(int,string)(pState.stateId);
				string stateId2 = conv!(int,string)(jt.stateId);
				strNFALine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
				strNFALine.pushBack("\t[label=\"epsilon\"];\n");
				append(strNFATable, strNFALine.getString());
				strNFALine.clear();
			}

			foreach(jt;this.inputSet.values()) {
				state = pState.getTransition(jt);
				foreach(kt;state) {
					string stateId1 = conv!(int,string)(pState.stateId);
					string stateId2 = conv!(int,string)(kt.stateId);
					strNFALine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
					strNFALine.pushBack("\t[label=\"" ~ jt ~ "\"];\n");
					append(strNFATable, strNFALine.getString());
					strNFALine.clear();
				}
			}	
			
		}

		append(strNFATable, "}");
		std.stream.File file = new std.stream.File("nfaGraph.dot", FileMode.OutNew);
		foreach(it;strNFATable) {
			file.writeString(it);
		}
		file.close();
		system("dot -T jpg nfaGraph.dot > nfaGraph.jpg");
	}
}