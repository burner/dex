/*! \file AG_RegEx.h
    \brief Regular Expression Parser
	\author Amer Gerzic

	Use it as following:					\n
											\n
	string strPattern;						\n
	int nPos = 0;							\n
											\n
	if(SetRegEx("....."))					\n
	{										\n
		if(FindFirst(...))					\n
		{									\n
			// Do something with result		\n
			while(FindNext(...))			\n
			{								\n
				// Process Result			\n
			}								\n
		}									\n
	}										\n
*/

#pragma once

// for debug STL exceeds 255 chars and MS compiler complains, so disable it
#pragma warning(disable:4786)
#pragma warning(disable:4503)

#include <string>
#include <sstream>
#include <cassert>
#include <stack>
#include <map>
#include <deque>
#include <vector>
#include <set>
#include <algorithm>
#include <list>
#include <iostream>

using namespace std;
		string IntToStr( int n ) {
  			ostringstream result;
  			result << n;
  			return result.str();
  		}


class CAG_RegEx  
{
public:
	//! State Class
	class CAG_State
	{
	protected:
		//! Transitions from this state to other 
		multimap<char, CAG_State*> m_Transition;

		//! State ID
		int m_nStateID;

		//! Set of NFA state from which this state is constructed
		set<CAG_State*> m_NFAStates;

	public:
		//! Default constructor
		CAG_State() : m_nStateID(-1), m_bAcceptingState(false) {};

		//! parameterized constructor
		CAG_State(int nID) : m_nStateID(nID), m_bAcceptingState(false) {};

		//! Constructs new state from the set of other states
		/*! This is necessary for subset construction algorithm
			because there a new DFA state is constructed from 
			one or more NFA states
		*/
		CAG_State(set<CAG_State*> NFAState, int nID)
		{
			m_NFAStates			= NFAState;
			m_nStateID			= nID;
			
			// DFA state is accepting state if it is constructed from 
			// an accepting NFA state
			m_bAcceptingState	= false;
			set<CAG_State*>::iterator iter;
			for(iter=NFAState.begin(); iter!=NFAState.end(); ++iter)
				if((*iter)->m_bAcceptingState)
					m_bAcceptingState = true;
		};

		int getID() const {
			return m_nStateID;
		}

		//! Copy Constructor
		CAG_State(const CAG_State &other)
		{ *this = other; };

		//! Destructor
		virtual ~CAG_State() {};

		//! True if this state is accepting state
		bool m_bAcceptingState;

		//! Adds a transition from this state to the other
		void AddTransition(char chInput, CAG_State *pState)
		{
			assert(pState != NULL);
			m_Transition.insert(make_pair(chInput, pState));
		};

		//! Removes all transition that go from this state to pState
		void RemoveTransition(CAG_State* pState)
		{
			multimap<char, CAG_State*>::iterator iter;
			for(iter=m_Transition.begin(); iter!=m_Transition.end();)
			{
				CAG_State *toState = iter->second;
				if(toState == pState)
					m_Transition.erase(iter++);
				else ++iter;
			}
		};

		//! Returns all transitions from this state on specific input
		void GetTransition(char chInput, vector<CAG_State*> &States)
		{
			// clear the array first
			States.clear();

			// Iterate through all values with the key chInput
			multimap<char, CAG_State*>::iterator iter;
			for(iter = m_Transition.lower_bound(chInput);
				iter!= m_Transition.upper_bound(chInput);
				++iter)
				{
					CAG_State *pState = iter->second;
					assert(pState != NULL);
					States.push_back(pState);
				}
		};


		//! Returns the state id in form of string
		string GetStateID()
		{
			string strRes;
			if(m_bAcceptingState) {
				strRes += "{";
				strRes += IntToStr(m_nStateID);
				strRes += "}";
			} else {
				strRes += IntToStr(m_nStateID);
			}
			return strRes;
		};

		/*! Returns the set of NFA states from 
			which this DFA state was constructed
		*/
		set<CAG_State*>& GetNFAState()
		{ return m_NFAStates; };

		//! Returns true if this state is dead end
		/*! By dead end I mean that this state is not
			accepting state and there are no transitions
			leading away from this state. This function
			is used for reducing the DFA.
		*/
		bool IsDeadEnd()
		{
			if(m_bAcceptingState)
				return false;
			if(m_Transition.empty())
				return true;
			
			multimap<char, CAG_State*>::iterator iter;
			for(iter=m_Transition.begin(); iter!=m_Transition.end(); ++iter)
			{
				CAG_State *toState = iter->second;
				if(toState != this)
					return false;
			}

			
			return true;
		};	

		//! Override the assignment operator
		CAG_State& operator=(const CAG_State& other)
		{ 
			m_Transition	= other.m_Transition; 
			m_nStateID		= other.m_nStateID;
			m_NFAStates		= other.m_NFAStates;
		};

		//! Override the comparison operator
		bool operator==(const CAG_State& other)
		{
			if(m_NFAStates.empty())
				return(m_nStateID == other.m_nStateID);
			else return(m_NFAStates == other.m_NFAStates);
		};
	};

	//! Structure to track the pattern recognition
	class CAG_PatternState
	{
	public:
		//! Default Constructor
		CAG_PatternState() : m_pState(NULL), m_nStartIndex(-1) {};

		//! Copy Constructor
		CAG_PatternState(const CAG_PatternState &other)
		{ *this = other; };

		//! Destructor
		virtual ~CAG_PatternState() {};

		//! Pointer to current state in DFA
		CAG_State* m_pState;

		//! 0-Based index of the starting position
		int m_nStartIndex;

		//! Override the assignment operator
		CAG_PatternState& operator=(const CAG_PatternState& other)
		{
			assert(other.m_pState != NULL);
			m_pState		= other.m_pState;
			m_nStartIndex	= other.m_nStartIndex;
			return *this;
		};
	};

	//! NFA Table
	typedef deque<CAG_State*> FSA_TABLE;

	/*! NFA Table is stored in a deque of CAG_States.
		Each CAG_State object has a multimap of 
		transitions where the key is the input
		character and values are the references to
		states to which it transfers.
	*/
	FSA_TABLE m_NFATable;

	//! DFA table is stores in same format as NFA table
	FSA_TABLE m_DFATable;

	//! Operand Stack
	/*! If we use the Thompson's Algorithm then we realize
		that each operand is a NFA automata on its own!
	*/
	stack<FSA_TABLE> m_OperandStack;

	//! Operator Stack
	/*! Operators are simple characters like "*" & "|" */
	stack<char> m_OperatorStack;

	//! Keeps track of state IDs
	int m_nNextStateID;

	//! Set of input characters
	set<char> m_InputSet;

	//! List of current partially found patterns
	list<CAG_PatternState*> m_PatternList;

	//! Contains the current patterns accessed
	int m_nPatternIndex;

	//! Contains the text to check
	string m_strText;

	//! Contains all found patterns
	vector<string> m_vecPattern;

	//! Contains all position where these pattern start in the text
	vector<int> m_vecPos;

	//! Constructs basic Thompson Construction Element
	/*! Constructs basic NFA for single character and
		pushes it onto the stack.
	*/
	void Push(char chInput);

	//! Pops an element from the operand stack
	/*! The return value is true if an element 
		was poped successfully, otherwise it is
		false (syntax error) 
	*/
	bool Pop(FSA_TABLE &NFATable);

	//! Checks is a specific character and operator
	bool IsOperator(char ch) { return((ch == 42) || (ch == 124) || (ch == 40) || (ch == 41) || (ch == '\a')); };

	//! Returns operator presedence
	/*! Returns true if presedence of opLeft <= opRight.
	
			Kleens Closure	- highest
			Concatenation	- middle
			Union			- lowest
	*/
	bool Presedence(char opLeft, char opRight)
	{
		if(opLeft == opRight)
			return true;

		if(opLeft == '*')
			return false;

		if(opRight == '*')
			return true;

		if(opLeft == '\a')
			return false;

		if(opRight == '\a')
			return true;

		if(opLeft == '|')
			return false;
		
		return true;
	};

	//! Checks if the specific character is input character
	bool IsInput(char ch) { return(!IsOperator(ch)); };

	//! Checks is a character left parantheses
	bool IsLeftParanthesis(char ch) { return(ch == 40); };

	//! Checks is a character right parantheses
	bool IsRightParanthesis(char ch) { return(ch == 41); };

	//! Evaluates the next operator from the operator stack
	bool Eval();

	//! Evaluates the concatenation operator
	/*! This function pops two operands from the stack 
		and evaluates the concatenation on them, pushing
		the result back on the stack.
	*/
	bool Concat();

	//! Evaluates the Kleen's closure - star operator
	/*! Pops one operator from the stack and evaluates
		the star operator on it. It pushes the result
		on the operand stack again.
	*/
	bool Star();

	//! Evaluates the union operator
	/*! Pops 2 operands from the stack and evaluates
		the union operator pushing the result on the
		operand stack.
	*/
	bool Union();

	//! Inserts char 8 where the concatenation needs to occur
	/*! The method used to parse regular expression here is 
		similar to method of evaluating the arithmetic expressions.
		A difference here is that each arithmetic expression is 
		denoted by a sign. In regular expressions the concatenation
		is not denoted by ny sign so I will detect concatenation
		and insert a character 8 between operands.
	*/
	string ConcatExpand(string strRegEx);

	//! Creates Nondeterministic Finite Automata from a Regular Expression
	bool CreateNFA(string strRegEx);

	//! Calculates the Epsilon Closure 
	/*! Returns epsilon closure of all states
		given with the parameter.
	*/
	void EpsilonClosure(set<CAG_State*> T, set<CAG_State*> &Res); 

	//! Calculates all transitions on specific input char
	/*! Returns all states rechible from this set of states
		on an input character.
 	*/
	void Move(char chInput, set<CAG_State*> T, set<CAG_State*> &Res);

	//! Converts NFA to DFA using the Subset Construction Algorithm
	void ConvertNFAtoDFA();

	//! Optimizes the DFA
	/*! This function scanns DFA and checks for states that are not
		accepting states and there is no transition from that state
		to any other state. Then after deleting this state we need to
		go through the DFA and delete all transitions from other states
		to this one.
	*/
	void ReduceDFA();

	//! Cleans up the memory
	void CleanUp()
	{
		// Clean up all allocated memory for NFA
		for(int i=0; i<m_NFATable.size(); ++i)
			delete m_NFATable[i];
		m_NFATable.clear();

		// Clean up all allocated memory for DFA
		for(int i=0; i<m_DFATable.size(); ++i)
			delete m_DFATable[i];
		m_DFATable.clear();

		// Reset the id tracking
		m_nNextStateID = 0;

		// Clear both stacks
		while(!m_OperandStack.empty())
			m_OperandStack.pop();
		while(!m_OperatorStack.empty())
			m_OperatorStack.pop();

		// Clean up the Input Character set
		m_InputSet.clear();

		// Clean up all pattern states
		list<CAG_PatternState*>::iterator iter;
		for(iter=m_PatternList.begin(); iter!=m_PatternList.end(); ++iter)
			delete *iter;
		m_PatternList.clear();
	};

	//! Searches the text for all occurences of the patterns
	/*! Returns true if single pattern is found or false if 
	    no pattern sis found.
	*/
	bool Find();

public:
	//! Default Constructor
	CAG_RegEx();

	//! Destructor
	virtual ~CAG_RegEx();

	//! Set Regular Expression
	/*! Set the string pattern to be searched for.
		Returns true if success othewise it returns false.
	*/
	bool SetRegEx(string strRegEx);

	//! Searches for the first occurence of a text pattern
	/*! If the pattern is found the function returns true
		together with starting positions (vecPos) and the patterns
		(vecPattern) found. THIS FUNCTION MUST BE CALLED FIRST.
		The return value is true if a pattern is found or false
		if nothing is found.
	*/
	bool FindFirst(string strText, int &nPos, string &strPattern);

	//! Searches for the next occurence of a text pattern
	/*! If the pattern is found the function returns true
		together with starting position array (vecPos) and the patterns
		(vecPattern) found. THIS FUNCTION MUST BE CALLED AFTER 
		THE FUNCTION FindFirst(...). 
		The return value is true if a pattern is found or false
		if nothing is found.
	*/
	bool FindNext(int &nPos, string &strPattern);
/*
	//! For Debuging purposes only
	void SaveNFATable()
	{
		CString strNFATable;

		// First line are input characters
		set<char>::iterator iter;
		for(iter = m_InputSet.begin(); iter != m_InputSet.end(); ++iter)
			strNFATable += "\t\t" + CString(*iter);
		// add epsilon
		strNFATable += "\t\tepsilon";
		strNFATable += "\n";

		// Now go through each state and record the transitions
		for(int i=0; i<m_NFATable.size(); ++i)
		{
			CAG_State *pState = m_NFATable[i];
			
			// Save the state id
			strNFATable += pState->GetStateID();

			// now write all transitions for each character
			vector<CAG_State*> State;
			for(iter = m_InputSet.begin(); iter != m_InputSet.end(); ++iter)
			{
				pState->GetTransition(*iter, State);
				CString strState;
				if(State.size()>0)
				{
					strState = State[0]->GetStateID();
					for(int i=1; i<State.size(); ++i)
						strState += "," + State[i]->GetStateID();
				}
				strNFATable += "\t\t" + strState;
			}

			// Add all epsilon transitions
			pState->GetTransition(0, State);
			CString strState;
			if(State.size()>0)
			{
				strState = State[0]->GetStateID();
				for(int i=1; i<State.size(); ++i)
					strState += "," + State[i]->GetStateID();
			}
			strNFATable += "\t\t" + strState + "\n";
		}

		// Save table to the file
		CStdioFile f;
		if(f.Open("C:\\NFATable.txt", CFile::modeCreate | CFile::modeWrite))
		{
			f.WriteString(strNFATable);
			f.Close();
		}
		else AfxMessageBox(_T("Could not save NFA Table to c:\\NFATable.txt"));
	};

	//! For Debuging purposes only
	void SaveDFATable()
	{
		CString strDFATable;

		// First line are input characters
		set<char>::iterator iter;
		for(iter = m_InputSet.begin(); iter != m_InputSet.end(); ++iter)
			strDFATable += "\t\t" + CString(*iter);
		strDFATable += "\n";

		// Now go through each state and record the transitions
		for(int i=0; i<m_DFATable.size(); ++i)
		{
			CAG_State *pState = m_DFATable[i];
			
			// Save the state id
			strDFATable += pState->GetStateID();

			// now write all transitions for each character
			vector<CAG_State*> State;
			for(iter = m_InputSet.begin(); iter != m_InputSet.end(); ++iter)
			{
				pState->GetTransition(*iter, State);
				CString strState;
				if(State.size()>0)
				{
					strState = State[0]->GetStateID();
					for(int i=1; i<State.size(); ++i)
						strState += "," + State[i]->GetStateID();
				}
				strDFATable += "\t\t" + strState;
			}
			strDFATable += "\n";
		}

		// Save table to the file
		CStdioFile f;
		if(f.Open("C:\\DFATable.txt", CFile::modeCreate | CFile::modeWrite))
		{
			f.WriteString(strDFATable);
			f.Close();
		}
		else AfxMessageBox(_T("Could not save DFA Table to c:\\DFATable.txt"));
	};
*/
	void SaveNFAGraph() {
		cout<<"saveNFAGraph"<<endl;
		string strNFAGraph = "digraph{\n";

		// Final states are double circled
		for(int i=0; i<m_NFATable.size(); ++i) {
			CAG_State *pState = m_NFATable[i];
			if(pState->m_bAcceptingState) {
				string strStateID = (pState->GetStateID());
				strNFAGraph += "\t" + (strStateID) + "\t[shape=doublecircle];\n";
			}
		}
		
		strNFAGraph += "\n";

		// Record transitions
		for(int i=0; i<m_NFATable.size(); ++i) {
			CAG_State *pState = m_NFATable[i];
			vector<CAG_State*> State;

			pState->GetTransition(0, State);
			for(int j=0; j<State.size(); ++j) {
				// Record transition
				string strStateID1 = pState->GetStateID();
				string strStateID2 = State[j]->GetStateID();
				strNFAGraph += "\t";
				strNFAGraph += (strStateID1);
				strNFAGraph += " -> ";
				strNFAGraph += (strStateID2);
				strNFAGraph += "\t[label=\"epsilon\"];\n";
			}

			set<char>::iterator iter;
			for(iter = m_InputSet.begin(); iter != m_InputSet.end(); ++iter) {
				pState->GetTransition(*iter, State);
				for(int j=0; j<State.size(); ++j) {
					// Record transition
					string strStateID1 = pState->GetStateID();
					string strStateID2 = State[j]->GetStateID();
					//strStateID1.Remove('{'); strStateID1.Remove('}');
					//strStateID2.Remove('{'); strStateID2.Remove('}');
					strNFAGraph += "\t" + (strStateID1) + " -> " + (strStateID2);
					strNFAGraph += "\t[label=\"";
					strNFAGraph += *iter;
					strNFAGraph += "\"];\n";
				}
			}
		}

		strNFAGraph += "}";
		cout<<strNFAGraph<<endl;

		// Save table to the file
		cout<<"done"<<endl;
	};
/*	
	void SaveDFAGraph()
	{
		CString strDFAGraph = _T("digraph{\n");

		// Final states are double circled
		for(int i=0; i<m_DFATable.size(); ++i)
		{
			CAG_State *pState = m_DFATable[i];
			if(pState->m_bAcceptingState)
			{
				CString strStateID = pState->GetStateID();
				strStateID.Remove('{'); strStateID.Remove('}');
				strDFAGraph += _T("\t") + strStateID + _T("\t[shape=doublecircle];\n");
			}
		}
		
		strDFAGraph += _T("\n");

		// Record transitions
		for(i=0; i<m_DFATable.size(); ++i)
		{
			CAG_State *pState = m_DFATable[i];
			vector<CAG_State*> State;

			pState->GetTransition(0, State);
			for(int j=0; j<State.size(); ++j)
			{
				// Record transition
				CString strStateID1 = pState->GetStateID();
				CString strStateID2 = State[j]->GetStateID();
				strStateID1.Remove('{'); strStateID1.Remove('}');
				strStateID2.Remove('{'); strStateID2.Remove('}');
				strDFAGraph += _T("\t") + strStateID1 + _T(" -> ") + strStateID2;
				strDFAGraph += _T("\t[label=\"epsilon\"];\n");
			}

			set<char>::iterator iter;
			for(iter = m_InputSet.begin(); iter != m_InputSet.end(); ++iter)
			{
				pState->GetTransition(*iter, State);
				for(int j=0; j<State.size(); ++j)
				{
					// Record transition
					CString strStateID1 = pState->GetStateID();
					CString strStateID2 = State[j]->GetStateID();
					strStateID1.Remove('{'); strStateID1.Remove('}');
					strStateID2.Remove('{'); strStateID2.Remove('}');
					strDFAGraph += _T("\t") + strStateID1 + _T(" -> ") + strStateID2;
					strDFAGraph += _T("\t[label=\"") + CString(*iter) + _T("\"];\n");
				}
			}
		}

		strDFAGraph += _T("}");

		// Save table to the file
		CStdioFile f;
		if(f.Open("C:\\DFAGraph.dot", CFile::modeCreate | CFile::modeWrite))
		{
			f.WriteString(strDFAGraph);
			f.Close();
		}
		else AfxMessageBox(_T("Could not save DFA Graph to c:\\DFAGraph.txt"));
	}; */
};
