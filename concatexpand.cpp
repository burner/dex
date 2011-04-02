#include <string>
#include <iostream>

using namespace std;

bool IsOperator(char ch) { return((ch == 42) || (ch == 124) || (ch == 40) || (ch == 41) || (ch == 8)); };

//! Checks if the specific character is input character
bool IsInput(char ch) { return(!IsOperator(ch)); };

//! Checks is a character left parantheses
bool IsLeftParanthesis(char ch) { return(ch == 40); };

//! Checks is a character right parantheses
bool IsRightParanthesis(char ch) { return(ch == 41); };

string ConcatExpand(string strRegEx)
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

int main() {
	string a = "ab*fz(t|u)t";	
	string b = ConcatExpand(a);
	cout<<(b == "a\bb*\bf\bz\b(t|u)\bt")<<endl;
	cout<<b.size()<<" "<<b<<endl;
	return 0;
}
