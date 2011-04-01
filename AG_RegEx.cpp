/*! \file AG_RegEx.cpp
    \brief implementation of the CAG_RegEx class
	\author Amer Gerzic
*/

#include "stdafx.h"
#include "RegExDemo.h"
#include "AG_RegEx.h"

#ifdef _DEBUG
#undef THIS_FILE
static char THIS_FILE[]=__FILE__;
#define new DEBUG_NEW
#endif

CAG_RegEx::CAG_RegEx()
{
	m_nNextStateID	= 0;
}

CAG_RegEx::~CAG_RegEx()
{
	// Clean up all allocated memory
	CleanUp();
}

BOOL CAG_RegEx::SetRegEx(string strRegEx)
{
	// 1. Clean up old regular expression
	CleanUp();

	// 2. Create NFA
	if(!CreateNFA(strRegEx))
		return FALSE;
	
	// 3. Convert to DFA
	ConvertNFAtoDFA();

	// 4. Reduce DFA
	ReduceDFA();

	return TRUE;
}

BOOL CAG_RegEx::FindFirst(string strText, int &nPos, string &strPattern)
{
	// Clean up all pattern states
	list<CAG_PatternState*>::iterator iter;
	for(iter=m_PatternList.begin(); iter!=m_PatternList.end(); ++iter)
		delete *iter;
	m_PatternList.clear();

	// reset the input text
	m_strText			= strText;

	// Find all patterns
	if(Find())
	{
		nPos			= m_vecPos[0];
		strPattern		= m_vecPattern[0];
		m_nPatternIndex	= 0;
		return TRUE;
	}

	return FALSE;
}

BOOL CAG_RegEx::FindNext(int &nPos, string &strPattern)
{
	++m_nPatternIndex;
	if(m_nPatternIndex<m_vecPos.size())
	{
		nPos			= m_vecPos[m_nPatternIndex];
		strPattern		= m_vecPattern[m_nPatternIndex];
		return TRUE;
	}
	return FALSE;
}

BOOL CAG_RegEx::Find()
{
	BOOL bRes = FALSE;

	// Clean up for new search
	m_vecPos.clear();
	m_vecPattern.clear();

	// if there is no DFA then there is no matching
	if(m_DFATable.empty())
		return FALSE;

	// Go through all input charactes 
	for(int i=0; i<m_strText.size(); ++i)
	{
		char c = m_strText[i];

		// Check all patterns states
		list<CAG_PatternState*>::iterator iter;
		for(iter=m_PatternList.begin(); iter!=m_PatternList.end(); ++iter)
		{
			CAG_PatternState *pPatternState = *iter;
			vector<CAG_State*> Transition; // must be at most one because this is DFA
			pPatternState->m_pState->GetTransition(c, Transition);
			if(!Transition.empty())
			{
				pPatternState->m_pState = Transition[0];
				if(Transition[0]->m_bAcceptingState)
				{
					m_vecPos.push_back(pPatternState->m_nStartIndex);
					m_vecPattern.push_back(m_strText.substr(pPatternState->m_nStartIndex, 
						i-pPatternState->m_nStartIndex+1));
				}
			}
			else
			{
				// Delete this pattern state
				iter = m_PatternList.erase(iter);
				--iter;
			}
		}

		// Check it against state 1 of the DFA
		CAG_State *pState = m_DFATable[0];
		vector<CAG_State*> Transition; // must be at most one because this is DFA
		pState->GetTransition(c, Transition);
		if(!Transition.empty())
		{
			CAG_PatternState *pPatternState = new CAG_PatternState();
			pPatternState->m_nStartIndex	= i;
			pPatternState->m_pState			= Transition[0];
			m_PatternList.push_back(pPatternState);

			// Check is this accepting state
			if(Transition[0]->m_bAcceptingState)
			{
				m_vecPos.push_back(i);
				string strTemp;
				strTemp += c;
				m_vecPattern.push_back(strTemp);
			}
		}
		else
		{
			// Check here is the entry state already accepting
			// because a* for example would accept 0 or many a's
			// whcih means that any character is actually accepted
			if(pState->m_bAcceptingState)
			{
				m_vecPos.push_back(i);
				string strTemp;
				strTemp += c;
				m_vecPattern.push_back(strTemp);
			}
		}
	}

	return(m_vecPos.size()>0);
}

BOOL CAG_RegEx::Eval()
{
	// First pop the operator from the stack
	if(m_OperatorStack.size()>0)
	{
		char chOperator = m_OperatorStack.top();
		m_OperatorStack.pop();

		// Check which operator it is
		switch(chOperator)
		{
		case  42:
			return Star();
			break;
		case 124:
			return Union();
			break;
		case   8:
			return Concat();
			break;
		}

		return FALSE;
	}

	return FALSE;
}

BOOL CAG_RegEx::Concat()
{
	// Pop 2 elements
	FSA_TABLE A, B;
	if(!Pop(B) || !Pop(A))
		return FALSE;

	// Now evaluate AB
	// Basically take the last state from A
	// and add an epsilon transition to the
	// first state of B. Store the result into
	// new NFA_TABLE and push it onto the stack
	A[A.size()-1]->AddTransition(0, B[0]);
	A.insert(A.end(), B.begin(), B.end());

	// Push the result onto the stack
	m_OperandStack.push(A);

	TRACE("CONCAT\n");

	return TRUE;
}

BOOL CAG_RegEx::Star()
{
	// Pop 1 element
	FSA_TABLE A, B;
	if(!Pop(A))
		return FALSE;

	// Now evaluate A*
	// Create 2 new states which will be inserted 
	// at each end of deque. Also take A and make 
	// a epsilon transition from last to the first 
	// state in the queue. Add epsilon transition 
	// between two new states so that the one inserted 
	// at the begin will be the source and the one
	// inserted at the end will be the destination
	CAG_State *pStartState	= new CAG_State(++m_nNextStateID);
	CAG_State *pEndState	= new CAG_State(++m_nNextStateID);
	pStartState->AddTransition(0, pEndState);

	// add epsilon transition from start state to the first state of A
	pStartState->AddTransition(0, A[0]);

	// add epsilon transition from A last state to end state
	A[A.size()-1]->AddTransition(0, pEndState);

	// From A last to A first state
	A[A.size()-1]->AddTransition(0, A[0]);

	// construct new DFA and store it onto the stack
	A.push_back(pEndState);
	A.push_front(pStartState);

	// Push the result onto the stack
	m_OperandStack.push(A);

	TRACE("STAR\n");

	return TRUE;
}

BOOL CAG_RegEx::Union()
{
	// Pop 2 elements
	FSA_TABLE A, B;
	if(!Pop(B) || !Pop(A))
		return FALSE;

	// Now evaluate A|B
	// Create 2 new states, a start state and
	// a end state. Create epsilon transition from
	// start state to the start states of A and B
	// Create epsilon transition from the end 
	// states of A and B to the new end state
	CAG_State *pStartState	= new CAG_State(++m_nNextStateID);
	CAG_State *pEndState	= new CAG_State(++m_nNextStateID);
	pStartState->AddTransition(0, A[0]);
	pStartState->AddTransition(0, B[0]);
	A[A.size()-1]->AddTransition(0, pEndState);
	B[B.size()-1]->AddTransition(0, pEndState);

	// Create new NFA from A
	B.push_back(pEndState);
	A.push_front(pStartState);
	A.insert(A.end(), B.begin(), B.end());

	// Push the result onto the stack
	m_OperandStack.push(A);

	TRACE("UNION\n");

	return TRUE;
}

string CAG_RegEx::ConcatExpand(string strRegEx)
{
	string strRes;

	for(int i=0; i<strRegEx.size()-1; ++i)
	{
		char cLeft	= strRegEx[i];
		char cRight = strRegEx[i+1];
		strRes	   += cLeft;
		if((IsInput(cLeft)) || (IsRightParanthesis(cLeft)) || (cLeft == '*'))
			if((IsInput(cRight)) || (IsLeftParanthesis(cRight)))
				strRes += char(8);
	}
	strRes += strRegEx[strRegEx.size()-1];

	return strRes;
}

BOOL CAG_RegEx::CreateNFA(string strRegEx)
{
	// Parse regular expresion using similar 
	// method to evaluate arithmetic expressions
	// But first we will detect concatenation and
	// insert char(8) at the position where 
	// concatenation needs to occur
	strRegEx = ConcatExpand(strRegEx);

	for(int i=0; i<strRegEx.size(); ++i)
	{
		// get the charcter
		char c = strRegEx[i];
		
		if(IsInput(c))
			Push(c);
		else if(m_OperatorStack.empty())
			m_OperatorStack.push(c);
		else if(IsLeftParanthesis(c))
			m_OperatorStack.push(c);
		else if(IsRightParanthesis(c))
		{
			// Evaluate everyting in paranthesis
			while(!IsLeftParanthesis(m_OperatorStack.top()))
				if(!Eval())
					return FALSE;
			// Remove left paranthesis after the evaluation
			m_OperatorStack.pop(); 
		}
		else
		{
			while(!m_OperatorStack.empty() && Presedence(c, m_OperatorStack.top()))
				if(!Eval())
					return FALSE;
			m_OperatorStack.push(c);
		}
	}

	// Evaluate the rest of operators
	while(!m_OperatorStack.empty())
		if(!Eval())
			return FALSE;

	// Pop the result from the stack
	if(!Pop(m_NFATable))
		return FALSE;

	// Last NFA state is always accepting state
	m_NFATable[m_NFATable.size()-1]->m_bAcceptingState = TRUE;

	return TRUE;
}

void CAG_RegEx::Push(char chInput)
{
	// Create 2 new states on the heap
	CAG_State *s0 = new CAG_State(++m_nNextStateID);
	CAG_State *s1 = new CAG_State(++m_nNextStateID);

	// Add the transition from s0->s1 on input character
	s0->AddTransition(chInput, s1);

	// Create a NFA from these 2 states 
	FSA_TABLE NFATable;
	NFATable.push_back(s0);
	NFATable.push_back(s1);

	// push it onto the operand stack
	m_OperandStack.push(NFATable);

	// Add this character to the input character set
	m_InputSet.insert(chInput);

	TRACE("PUSH %s\n", CString(chInput));
}

BOOL CAG_RegEx::Pop(FSA_TABLE &NFATable)
{
	// If the stack is empty we cannot pop anything
	if(m_OperandStack.size()>0)
	{
		NFATable = m_OperandStack.top();
		m_OperandStack.pop();
		return TRUE;
	}

	return FALSE;
}

void CAG_RegEx::EpsilonClosure(set<CAG_State*> T, set<CAG_State*> &Res)
{
	Res.clear();
	
	// Initialize result with T because each state
	// has epsilon closure to itself
	Res = T;

	// Push all states onto the stack
	stack<CAG_State*> unprocessedStack;
	set<CAG_State*>::iterator iter;
	for(iter=T.begin(); iter!=T.end(); ++iter)
		unprocessedStack.push(*iter);

	// While the unprocessed stack is not empty
	while(!unprocessedStack.empty())
	{
		// Pop t, the top element from unprocessed stack
		CAG_State* t = unprocessedStack.top();
		unprocessedStack.pop();

		// Get all epsilon transition for this state
		vector<CAG_State*> epsilonStates;
		t->GetTransition(0, epsilonStates);

		// For each state u with an edge from t to u labeled epsilon
		for(int i=0; i<epsilonStates.size(); ++i)
		{
			CAG_State* u = epsilonStates[i];
			// if u not in e-closure(T)
			if(Res.find(u) == Res.end())
			{
				Res.insert(u);
				unprocessedStack.push(u);
			}
		}
	}
}

void CAG_RegEx::Move(char chInput, set<CAG_State*> T, set<CAG_State*> &Res)
{
	Res.clear();

	/* This is very simple since I designed the NFA table
	   structure in a way that we just need to loop through
	   each state in T and recieve the transition on chInput.
	   Then we will put all the results into the set, which
	   will eliminate duplicates automatically for us.
	*/
	set<CAG_State*>::iterator iter;
	for(iter=T.begin(); iter!=T.end(); ++iter)
	{
		// Get all transition states from this specific
		// state to other states
		CAG_State* pState = *iter;
		vector<CAG_State*> States;
		pState->GetTransition(chInput, States);

		// Now add these all states to the result
		// This will eliminate duplicates
		for(int i=0; i<States.size(); ++i)
			Res.insert(States[i]);
	}
}

void CAG_RegEx::ConvertNFAtoDFA()
{
	// Clean up the DFA Table first
	for(int i=0; i<m_DFATable.size(); ++i)
		delete m_DFATable[i];
	m_DFATable.clear();

	// Check is NFA table empty
	if(m_NFATable.size() == 0)
		return;

	// Reset the state id for new naming
	m_nNextStateID = 0;

	// Array of unprocessed DFA states
	vector<CAG_State*> unmarkedStates;

	// Starting state of DFA is epsilon closure of 
	// starting state of NFA state (set of states)
	set<CAG_State*> DFAStartStateSet;
	set<CAG_State*> NFAStartStateSet;
	NFAStartStateSet.insert(m_NFATable[0]);
	EpsilonClosure(NFAStartStateSet, DFAStartStateSet);

	// Create new DFA State (start state) from the NFA states
	CAG_State *DFAStartState = new CAG_State(DFAStartStateSet, ++m_nNextStateID);

	// Add the start state to the DFA
	m_DFATable.push_back(DFAStartState);

	// Add the starting state to set of unprocessed DFA states
	unmarkedStates.push_back(DFAStartState);
	while(!unmarkedStates.empty())
	{
		// process an unprocessed state
		CAG_State* processingDFAState = unmarkedStates[unmarkedStates.size()-1];
		unmarkedStates.pop_back();

		// for each input signal a
		set<char>::iterator iter;
		for(iter=m_InputSet.begin(); iter!=m_InputSet.end(); ++iter)
		{
			set<CAG_State*> MoveRes, EpsilonClosureRes;
			Move(*iter, processingDFAState->GetNFAState(), MoveRes);
			EpsilonClosure(MoveRes, EpsilonClosureRes);

			// Check is the resulting set (EpsilonClosureSet) in the
			// set of DFA states (is any DFA state already constructed
			// from this set of NFA states) or in pseudocode:
			// is U in D-States already (U = EpsilonClosureSet)
			BOOL bFound		= FALSE;
			CAG_State *s	= NULL;
			for(i=0; i<m_DFATable.size(); ++i)
			{
				s = m_DFATable[i];
				if(s->GetNFAState() == EpsilonClosureRes)
				{
					bFound = TRUE;
					break;
				}
			}
			if(!bFound)
			{
				CAG_State* U = new CAG_State(EpsilonClosureRes, ++m_nNextStateID);
				unmarkedStates.push_back(U);
				m_DFATable.push_back(U);
				
				// Add transition from processingDFAState to new state on the current character
				processingDFAState->AddTransition(*iter, U);
			}
			else
			{
				// This state already exists so add transition from 
				// processingState to already processed state
				processingDFAState->AddTransition(*iter, s);
			}
		}
	}
}

void CAG_RegEx::ReduceDFA()
{
	// Get the set of all dead end states in DFA
	set<CAG_State*> DeadEndSet;
	for(int i=0; i<m_DFATable.size(); ++i)
		if(m_DFATable[i]->IsDeadEnd())
			DeadEndSet.insert(m_DFATable[i]);

	// If there are no dead ends then there is nothing to reduce
	if(DeadEndSet.empty())
		return;

	// Remove all transitions to these states
	set<CAG_State*>::iterator iter;
	for(iter=DeadEndSet.begin(); iter!=DeadEndSet.end(); ++iter)
	{
		// Remove all transitions to this state
		for(i=0; i<m_DFATable.size(); ++i)
			m_DFATable[i]->RemoveTransition(*iter);

		// Remove this state from the DFA Table
		deque<CAG_State*>::iterator pos;
		for(pos=m_DFATable.begin(); pos!=m_DFATable.end(); ++pos)
			if(*pos == *iter)
				break;
		// Erase element from the table
		m_DFATable.erase(pos);

		// Now free the memory used by the element
		delete *iter;
	}
}
