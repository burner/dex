module dex.strutil;

import dex.parseerror;

import hurt.string.stringbuffer;
import hurt.util.array;

import std.stdio;

public immutable char LP = '\v';
public immutable char RP = '\f';
public immutable char CC = '\a';
public immutable char UN = cast(char)6;
public immutable char ST = cast(char)14;

public immutable(T)[] expandRange(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	StringBuffer!(T) ret = new StringBuffer!(T)(str.length*3);	
	for(size_t i = 0; i < str.length; i++) {
		writeln(i, " ", ret.getString());
		// in case you find the union char [ . Search till you find the matching ]
		if(str[i] == '[' && i > 0 && str[i-1] == '\\') {
			ret.popBack();
			ret.pushBack(str[i]);
		} else if(str[i] == ']' && i > 0 && str[i-1] == '\\') {
			ret.popBack();
			ret.pushBack(str[i]);
		} else if(str[i] == '*' && i > 0 && str[i-1] == '\\') {
			ret.popBack();
			ret.pushBack(str[i]);
		} else if(str[i] == '*' && i > 0 && str[i-1] != '\\') {
			ret.pushBack(ST);
		} else if(str[i] == '[' && i > 0 && str[i-1] != '\\') {
			StringBuffer!(T) tmp = new StringBuffer!(T)();
			while(i < str.length) {
				if(str[i] == ']' && str[i-1] != '\\') {
					tmp = tmp.pushBack(str[i]);
					break;
				} else if(str[i] == '[' && str[i-1] == '\\') {
					tmp.popBack();
					tmp.pushBack(str[i]);
					i++;
				} else if(str[i] == ']' && str[i-1] == '\\') {
					tmp.popBack();
					tmp.pushBack(str[i]);
					i++;
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
	assert("[]"~ST == expandRange!(char)("[]*"), 
			expandRange!(char)("[]*"));
	assert("[]" == expandRange!(char)("[]"), 
			expandRange!(char)("[]"));
	assert("rt\v\frt" == expandRange!(char)("rt[]rt"), 
			expandRange!(char)("rt[]rt"));
	assert("rt[]rt" == expandRange!(char)("rt\\[\\]rt"), 
			expandRange!(char)("rt\\[\\]rt"));
	assert("rt\v[" ~ UN ~ "]\frt" == expandRange!(char)("rt[\\[\\]]rt"), 
			expandRange!(char)("rt[\\[\\]]rt"));
	assert("rt\va" ~ UN ~ 'b' ~ UN ~ 'c' ~ UN ~ '[' ~ UN ~ ']' ~ "\frt" == expandRange!(char)("rt[abc\\[\\]]rt"), 
			expandRange!(char)("rt[abc\\[\\]]rt"));
	assert("rt\v0"~UN~'1'~UN~'2'~UN~'3'~UN~'4'~UN~'5'~UN~'6'~UN~"7\frt" == expandRange!(char)("rt[:odigit:]rt"), 
			expandRange!(char)("rt[:odigit:]rt"));
	assert("rt\v0"~UN~'1'~UN~"2\frt" == expandRange!(char)("rt[012]rt"), 
			expandRange!(char)("rt[012]rt"));
	assert("rt\va"~UN~'t'~UN~"h\frt" == expandRange!(char)("rt[ath]rt"), 
			expandRange!(char)("rt[ath]rt"));
	assert("rt\va"~UN~'t'~UN~"h\f[]rt" == expandRange!(char)("rt[ath]\\[\\]rt"), 
			expandRange!(char)("rt[ath]\\[\\]rt"));
}

public immutable(T)[] setUnionSymbol(T)(T[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	//writeln(__FILE__,__LINE__,": ",str);
	if(str.length == 0)
		return "";
	T[] ret = new T[(str.length*2) -1];
	size_t ptr = 0;
	ret[ptr++] = str[0];
	for(size_t i = 1; i < str.length; i++) {
		ret[ptr++] = cast(T)6;
		ret[ptr++] = str[i];
	}
	return ret[0..ptr].idup;
}

unittest {
}


public int stringCompare(string a, string b) {
	//if(a.length > b.length) {
	//	return -2;
	//} else if(a.length < b.length) {
	//	return -1;
	//}
	int idx = 0;
	foreach(it; a) {
		if(it != b[idx]) {
			//write(it, " != ", b[idx], " ");
			return idx;
		}
		idx++;
	}
	return -3;
}

public immutable(T)[] expandRangeDirect(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	writeln(__LINE__, " ",str);
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
			return ('\v' ~ setUnionSymbol!(T)(lowChar ~ upperChar ~ digits) ~ '\f').idup;
		case ":word:": 
		case "a-zA-Z0-9_":
			return ('\v' ~ setUnionSymbol!(T)(lowChar ~ upperChar ~ digits) ~ '_' ~ '\f').idup;
		case ":alpha:": 
		case "a-zA-Z":
			return ('\v' ~ setUnionSymbol!(T)(lowChar ~ upperChar) ~ '\f').idup;
		case ":digit:": 
		case "0-9":
			return ('\v' ~ setUnionSymbol!(T)(digits) ~ '\f').idup;
		case ":upper:":
			return ('\v' ~ setUnionSymbol!(T)(upperChar) ~ '\f').idup;
		case ":lower:":
			return ('\v' ~ setUnionSymbol!(T)(lowChar) ~ '\f').idup;
		case ":xdigit:":
			return ('\v' ~ setUnionSymbol!(T)(xdigits) ~ '\f').idup;
		case ":odigit:":
			return ('\v' ~ setUnionSymbol!(T)(digits[0..8]) ~ '\f').idup;
		default: {
			return ('\v' ~ setUnionSymbol!(T)(str.dup) ~ '\f').idup;	
		}
	}
	return null;
}

public immutable(T)[] concatExpand(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	writeln(__LINE__, " ", str);
	str = expandRange!(T)(str);
	writeln(__LINE__, " ", str);
	T[] ret = new T[str.length*3u];
	uint retPtr = 0;
	T cLeft;
	T cRight;
	for(size_t i = 0; i < str.length-1; i++) {
		cLeft = str[i];
		cRight = str[i+1];
		ret[retPtr++] = cLeft;
		if(isInput!(T)(cLeft) || isRightParanthesis!(T)(cLeft) 
				|| cLeft == ST) {
			if(isInput(cRight) || isLeftParanthesis!(T)(cRight)) {
				ret[retPtr++] = CC;
			}
		}
	}
	ret[retPtr++] = str[$-1];
	return ret[0..retPtr].idup;
}

immutable(T)[] stringWrite(T)(immutable(T)[] str) {
	T[] ret = new T[str.length];
	foreach(idx,it;str) {
		if(it == '\a') {
			ret[idx] = '.';
		} else if(it == '\v') {
			ret[idx] = '[';
		} else if(it == '\f') {
			ret[idx] = ']';
		} else if(it == ST) {
			ret[idx] = '*';
		} else if(it == UN) {
			ret[idx] = '|';
		} else {
			ret[idx] = it;
		}
	}
	return ret.idup;
}

unittest {
	assert("f\ad"~ST == concatExpand("fd*"), 
		concatExpand("fd*"));

	//writeln("\n\n");
	//writeln(stringCompare("f\ad"~ST~"\a\vt"~UN~"r\f\aw",concatExpand("fd*[tr]w"))); 
	//writeln("\n\n");

	assert("f\ad"~ST~"\a\vt"~UN~"r\f\aw" == concatExpand("fd*[tr]w"), 
		stringWrite(concatExpand("fd*[tr]w")));
}

public pure bool isOperator(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return ch == ST || ch == UN || ch == LP || ch == RP || ch == CC;
}

public pure bool isInput(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return !isOperator!(T)(ch);
}

public pure bool isRightParanthesis(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return ch == RP;
}

public pure bool isLeftParanthesis(T)(T ch)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	return ch == LP;
}

public pure bool presedence(T)(T opLeft, T opRight)
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	if(opLeft == opRight)
		return true;

	//if(opLeft == '*')
	if(opLeft == ST)
		return false;

	//if(opRight == '*')
	if(opRight == ST)
		return true;

	//if(opLeft == '\a')
	if(opLeft == CC)
		return false;

	//if(opRight == '\a')
	if(opRight == CC)
		return true;

	if(opLeft == UN)
		return false;
	
	return true;
}
/*
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
}*/
