module dex.regex;

import dex.state;
import dex.list;
import dex.set;
import dex.patternstate;
import dex.util;

import hurt.conv.conv;
import hurt.container.dlst;
import hurt.container.stack;
import hurt.container.vector;
import hurt.util.stacktrace;
import hurt.util.array;
import hurt.string.stringbuffer;

import std.stdio;
import std.stream;

alias DLinkedList!(State) FSA_Table;

class RegEx {
	FSA_Table nfaTable;
	FSA_Table dfaTable;
	Stack!(FSA_Table) operandStack;
	Stack!(char) operatorStack;

	int nextStateId;

	Set!(char) inputSet;

	List!(PatternState) patternList;

	int patternIndex;

	string strText;

	Vector!(int) vecPos;

	this() {
		this.nfaTable = new FSA_Table();
		this.dfaTable = new FSA_Table();
		this.operandStack = new Stack!(FSA_Table)();
		this.operatorStack = new Stack!(char)();
		this.inputSet = new Set!(char);
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
				operatorStack.push(it);
			} else if(isLeftParanthesis!(char)(it)) {
				debug(RegExDebug) writeln(__FILE__,__LINE__, " isLeftParanthesis");
				operatorStack.push(it);
			} else if(isRightParanthesis!(char)(it)) {
				debug(RegExDebug) writeln(__FILE__,__LINE__, " isRightParanthesis");
				while(!isLeftParanthesis!(char)(operatorStack.top())) {
					if(!this.eval()) {
						return false;
					}
				}
				operatorStack.pop();
			} else {
				debug(RegExDebug) writeln(__FILE__,__LINE__, " else");
				while(!operatorStack.empty() && presedence!(char)(it, operatorStack.top())) {
					debug(RegExDebug) writeln(__FILE__,__LINE__, " !(if.eval)");
					if(!this.eval()) {
						return false;
					}
				}
				debug(RegExDebug) writeln(__FILE__,__LINE__, " operatorStack.push ", it);
				operatorStack.push(it);
			}
		}

		while(!operatorStack.empty()) {
			if(!this.eval()) {
				return false;
			}
		}

		if(!this.pop(this.nfaTable)) {
			return false;
		}

		this.nfaTable.get(this.nfaTable.getSize() - 1u).acceptingState = true;
		return true;
		
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

		operandStack.push(table);

		inputSet.insert(chInput);
	}

	bool pop(ref FSA_Table nfaTable) {
		debug scope StackTrace st = new StackTrace(__FILE__, __LINE__,
			"pop");

		debug(RegExDebug) writeln(__FILE__,__LINE__, " this.operandStack.size ", this.operandStack.getSize());
			
		if(this.operandStack.getSize() > 0) {
			nfaTable = operandStack.top();
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
		A.get(A.getSize()-1).addTransition(0, B.get(0));
		debug(RegExDebug) writeln(__FILE__,__LINE__, " after A.get");
		//A.insert(A.end(), B.begin(), B.end());
	
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
		A.get(A.getSize()-1).addTransition(0, pEndState);
	
		// From A last to A first state
		//A[A.size()-1]->AddTransition(0, A[0]);
		A.get(A.getSize()-1).addTransition(0, A.get(0));

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
		A.get(A.getSize()-1).addTransition(0, pEndState);
		B.get(B.getSize()-1).addTransition(0, pEndState);
	
		// Create new NFA from A
		B.pushBack(pEndState);
		A.pushFront(pStartState);
		//A.insert(A.end(), B.begin(), B.end()); TODO
	
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

	void writeNFAGraph() {
		string[] strNFATable = ["digraph{\n"];
		StringBuffer!(char) strNFALine = new StringBuffer!(char)(16);
		foreach(it;this.nfaTable) {
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
		foreach(pState;this.nfaTable) {
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
		std.stream.File file = new std.stream.File("nfaGraph.dot", FileMode.Out);
		foreach(it;strNFATable) {
			file.writeString(it);
		}
		file.close();
		
	}
}
