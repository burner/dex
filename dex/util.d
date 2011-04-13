module dex.util;

import hurt.string.stringbuffer;

public pure immutable(T)[] expandRange(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	T[] ret = new T[str.length*3u];
	uint retPtr = 0;
	for(size_t i = 0; i < str.lenght-1; i++) {
		if(str[i] == '[' && i > 0 && str[i-1] != '\') {
			immutable(T)[] tmp = "";
			i++;
			while(i < str.length) {
				if(str[i] == ']' && str[i-1] != '\') {
					break;
				} else {
					tmp = append(tmp, str[i]);
					i++;
				}
			}
		} else if(str[i] == '[' && i == 0) {
			ret = appendWithIdx!(char)(ret, retPtr++, str[i]);
		}
	}

}

public pure immutable(T)[] expandRangeDirect(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	immutable(T)[] upperChar = ['A','B','C','D','E','F','G','H','I','J','K','L',
		'M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
	immutable(T)[] lowChar = ['a','b','c','d','e','f','g','h','i','j','k','l',
		'm','n','o','p','q','r','s','t','u','v','w','x','y','z'];
	immutable(T)[] digits = ['0','1','2','3','4','5','6','7','8','9'];
	immutable(T)[] xdigits = ['A','B','C','D','E','F','0','1','2','3','4','5',
		'6','7','8','9','a','b','c','d','e','f'];
	switch(str) {
		case ":alnum:": .. case "a-zA-Z0-9":
			return '\f' ~ lowchar ~ upperChar ~ digits ~ '\f';
		case ":word:": .. case "a-zA-Z0-9_":
			return '\f' ~ lowchar ~ upperChar ~ digits ~ '_' ~ '\f';
		case ":alpha:": .. case "a-zA-Z":
			return '\f' ~ lowchar ~ upperChar ~ '\f';
		case ":digit:": .. case "0-9":
			return '\f' ~ digits ~ '\f';
		case ":upper:":
			return '\f' ~ upperChar ~ '\f';
		case ":lower:":
			return '\f' ~ lowerChar ~ '\f';
		case ":xdigit:":
			return '\f' ~ xdigits ~ '\f';
		case ":odigit:":
			return '\f' ~ digits[0..8] ~ '\f';
		default:
			return '\f' ~ str ~ '\f';	
	}
	return null;
}

public pure immutable(T)[] concatExpand(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	T[] ret = new T[str.length*3u];
	uint retPtr = 0;
	T cLeft;
	T cRight;
	for(size_t i = 0; i < str.length-1; i++) {
		cLeft = str[i];
		cRight = str[i+1];
		ret[retPtr++] = cLeft;
		if(isInput!(T)(cLeft) || isRightParanthesis!(T)(cLeft) 
				|| cLeft == '*') {
			if(isInput(cRight) || isLeftParanthesis!(T)(cRight)) {
				ret[retPtr++] = '\a';
			}
		}
	}
	ret[retPtr++] = str[$-1];
	return ret[0..retPtr].idup;
}

unittest {
	assert("f\ad*\a(t|r)\aw" == concatExpand("fd*(t|r)w"));
	assert("f\ad*\a(t|w|q|o|r)\aw" == concatExpand("fd*(t|w|q|o|r)w"));
}

public pure bool isOperator(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return ch == '*' || ch == '|' || ch == '(' || ch == ')' || ch == '\a';
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

public pure bool presedence(T)(T opLeft, T opRight)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
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
}
