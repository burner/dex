module dex.strutil;

import dex.parseerror;

import hurt.string.stringbuffer;
import hurt.util.array;

import std.stdio;

public immutable(T)[] expandRange(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	StringBuffer!(T) ret = new StringBuffer!(T)(str.length*3);	
	for(size_t i = 0; i < str.length; i++) {
		// in case you find the union char [ . Search till you find the matching ]
		if(str[i] == '[' && i > 0 && str[i-1] != '\\') {
			StringBuffer!(T) tmp = new StringBuffer!(T)();
			while(i < str.length) {
				if(str[i] == ']' && str[i-1] != '\\') {
					tmp = tmp.pushBack(str[i]);
					break;
				} else {
					tmp = tmp.pushBack(str[i]);
					i++;
				}
			}
			if(str[i] != ']') {
				throw new ParseError("Expected char ] not found");
			}
			ret.pushBack(expandRangeDirect!(T)(tmp.getString()[1..$-1]));
			continue;
		} else if(str[i] == '[' && i == 0) {
			ret.pushBack(str[i]);
		} else {
			ret.pushBack(str[i]);
		}
	}
	return ret.getString();
}

unittest {
	assert("[]" == expandRange!(char)("[]"), 
			expandRange!(char)("[]"));
	assert("rt\f\frt" == expandRange!(char)("rt[]rt"), 
			expandRange!(char)("rt[]rt"));
	assert("rt\\[\\]rt" == expandRange!(char)("rt\\[\\]rt"), 
			expandRange!(char)("rt\\[\\]rt"));
	assert("rt\f\\[\\]\frt" == expandRange!(char)("rt[\\[\\]]rt"), 
			expandRange!(char)("rt[\\[\\]]rt"));
	assert("rt\fabc\\[\\]\frt" == expandRange!(char)("rt[abc\\[\\]]rt"), 
			expandRange!(char)("rt[abc\\[\\]]rt"));
	writeln(stringCompare("rt\f01234567890\frt",expandRange!(char)("rt[:digit:]rt"))); 
	assert("rt\f01234567890\frt" == expandRange!(char)("rt[:digit:]rt"), 
			expandRange!(char)("rt[:digit:]rt"));
}

public pure int stringCompare(string a, string b) {
	if(a.length > b.length) {
		return -2;
	} else if(a.length < b.length) {
		return -1;
	}
	foreach(idx, it; a) {
		if(it != b[idx]) {
			return idx;
		}
	}
	return -3;
}

public immutable(T)[] expandRangeDirect(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	writeln(str);
	T[] upperChar = ['A','B','C','D','E','F','G','H','I','J','K','L',
		'M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
	T[] lowChar = ['a','b','c','d','e','f','g','h','i','j','k','l',
		'm','n','o','p','q','r','s','t','u','v','w','x','y','z'];
	T[] digits = ['0','1','2','3','4','5','6','7','8','9'];
	T[] xdigits = ['A','B','C','D','E','F','0','1','2','3','4','5',
		'6','7','8','9','a','b','c','d','e','f'];
	switch(str) {
		case ":alnum:": 
		case "a-zA-Z0-9":
			return ('\f' ~ lowChar ~ upperChar ~ digits ~ '\f').idup;
		case ":word:": 
		case "a-zA-Z0-9_":
			return ('\f' ~ lowChar ~ upperChar ~ digits ~ '_' ~ '\f').idup;
		case ":alpha:": 
		case "a-zA-Z":
			return ('\f' ~ lowChar ~ upperChar ~ '\f').idup;
		case ":digit:": 
		case "0-9":
			return ('\f' ~ digits ~ '\f').idup;
		case ":upper:":
			return ('\f' ~ upperChar ~ '\f').idup;
		case ":lower:":
			return ('\f' ~ lowChar ~ '\f').idup;
		case ":xdigit:":
			return ('\f' ~ xdigits ~ '\f').idup;
		case ":odigit:":
			return ('\f' ~ digits[0..8] ~ '\f').idup;
		default: {
			return ('\f' ~ str.dup ~ '\f').idup;	
		}
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
