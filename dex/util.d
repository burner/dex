module dex.util;

import hurt.string.stringbuffer;

public pure immutable(T)[] concatExpand(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	T[] ret = new T[str.length*3u];
	uint retPtr = 0;
	T cLeft;
	T cRight;
	for(uint i = 0; i < str.length-1; i++) {
		cLeft = str[i];
		cRight = str[i+1];
		ret[retPtr++] = cLeft;
		if(isInput!(T)(cLeft) || isRightParanthesis!(T)(cLeft) 
				|| cLeft == '*') {
			if(isInput(cRight) || isLeftParanthesis!(T)(cRight)) {
				ret[retPtr++] = '\b';
			}
		}
	}
	ret[retPtr++] = str[$-1];
	return ret[0..retPtr].idup;
}

unittest {
	assert("f\bd*\b(t|r)\bw" == concatExpand("fd*(t|r)w"));
	assert("f\bd*\b(t|w|q|o|r)\bw" == concatExpand("fd*(t|w|q|o|r)w"));
}

public pure bool isOperator(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return ch == '*' || ch == '|' || ch == '(' || ch == ')' || ch == '\b';
}

public pure bool isInput(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return !isOperator!(T)(ch);
}

public pure bool isRightParanthesis(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return ch == ')';
}

public pure bool isLeftParanthesis(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return ch == '(';
}
