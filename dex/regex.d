module dex.regex;

import dex.state;
import dex.list;
import dex.set;
import dex.patternstate;
import dex.util;

import hurt.container.dlst;
import hurt.container.stack;
import hurt.container.vector;

import std.stdio;

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

	bool createNFA(string str) {
		str = concatExpand(str);
		writeln(__FILE__,__LINE__, " ", str, " :length ",str.length);
			
		foreach(idx,it;str) {
			if(isInput!(char)(it)) {
				this.push(it);
			} else if(operatorStack.empty()) {
				operatorStack.push(it);
			} else if(isLeftParanthesis!(char)(it)) {
				operatorStack.push(it);
			} else if(isRightParanthesis!(char)(it)) {
				while(!isLeftParanthesis!(char)(operatorStack.top())) {
					if(!this.eval()) {
						return false;
					}
				}
				operatorStack.pop();
			} else {
				while(!operatorStack.empty() && presedence!(char)(it, operatorStack.top())) {
					if(!this.eval()) {
						return false;
					}
				}
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
		State s0 = new State(++nextStateId);
		State s1 = new State(++nextStateId);
		s0.addTransition(chInput, s1);

		FSA_Table table = new FSA_Table();
		table.pushBack(s0);
		table.pushBack(s1);

		operandStack.push(table);

		inputSet.insert(chInput);
	}

	bool pop(FSA_Table nfaTable) {
		if(this.operandStack.getSize() > 0) {
			nfaTable = operandStack.top();
			operandStack.pop();
			return true;
		}
		return false;
	}

	bool eval() {
		// First pop the operator from the stack
		if(this.operatorStack.getSize()>0) {
			char chOperator = this.operatorStack.top();
			this.operatorStack.pop();
	
			// Check which operator it is
			switch(chOperator) {
				case  '*':
					return this.Star();
				case '|':
					return this.Union();
				case '\b':
					return this.Concat();
			}
	
			return false;
		}
	
		return false;
	}

	bool Concat() {
		// Pop 2 elements
		FSA_Table A, B;
		if(!this.pop(B) || !this.pop(A))
			return false;
	
		// Now evaluate AB
		// Basically take the last state from A
		// and add an epsilon transition to the
		// first state of B. Store the result into
		// new NFA_TABLE and push it onto the stack

		//A[A.size()-1].AddTransition(0, B[0]);
		A.get(A.getSize()-1).addTransition(0, B.get(0));
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
}
