module dex.util;

import hurt.string.stringbuffer;

public pure immutable(T)[] concatExpand(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	StringBuffer!(T) ret = new StringBuffer!(T)(str.length*2u);
	T cLeft;
	T cRight;
	for(uint i = 0; i < str.length-1; i++) {
		cLeft = str[i];
		cRight = str[i+1];
		ret.pushBack(cLeft);
	}
}

public pure bool isOperator(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return ch == '*' || ch == '|' || ch == '(' || ch == ')' || ch == '\b';
}

public pure bool isInput(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return !isOperator!(T)(ch);
}
