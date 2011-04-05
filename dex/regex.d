module dex.regex;

import dex.state;
import dex.list;
import dex.set;
import dex.patternstate;
import dex.util;

import hurt.container.dlst;
import hurt.container.stack;
import hurt.container.vector;

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
				while(!operatorStack.empty() && presedence(it, operatorStack.top())) {
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

		this.nfaTable.get(this.nfaTable.getSize() - 1u).bAcceptionState = true;
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
}
