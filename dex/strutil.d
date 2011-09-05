module dex.strutil;

import dex.parseerror;

import hurt.io.stdio;
import hurt.string.stringbuffer;
import hurt.conv.conv;
import hurt.util.array;

public immutable char LP = '\v';
public immutable char RP = '\f';
public immutable char CC = '\a';
public immutable char UN = cast(char)6;
public immutable char ST = cast(char)14;
/*
public immutable(T)[] expandRange(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	StringBuffer!(T) ret = new StringBuffer!(T)(str.length*3);	
	for(size_t i = 0; i < str.length; i++) {
		// writeln(i, " ", ret.getString());
		// in case you find the union char [ . 
		// Search till you find the matching ]
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
		} else if((str[i] == '[' && i > 0 && str[i-1] != '\\')
				|| (str[i] == '[' && i == 0)) {
			StringBuffer!(T) tmp = new StringBuffer!(T)();
			tmp.pushBack(str[i]);
			i++;
			while(i < str.length) {
				if(str[i] == ']' && i > 0 && str[i-1] != '\\') {
					tmp = tmp.pushBack(str[i]);
					break;
				} else if(str[i] == '[' && i > 0  && str[i-1] == '\\') {
					tmp.popBack();
					tmp.pushBack(str[i]);
					i++;
				} else if(str[i] == '[' && i > 0  && str[i-1] != '\\') {
					throw new ParseError("An [ inside an [ environment " ~
						"is useless str="~str);
				} else if(str[i] == ']'  && i > 0 && str[i-1] == '\\') {
					tmp.popBack();
					tmp.pushBack(str[i]);
					i++;
				} else if(str[i] == '[' && i == 0) {
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
	assert("\v\f"~ST == expandRange!(char)("[]*"), 
		stringWrite!(char)(expandRange!(char)("[]*")));
	assert("\v\f" == expandRange!(char)("[]"), 
		expandRange!(char)("[]"));
	assert("rt\v\frt" == expandRange!(char)("rt[]rt"), 
		expandRange!(char)("rt[]rt"));
	assert("rt[]rt" == expandRange!(char)("rt\\[\\]rt"), 
		expandRange!(char)("rt\\[\\]rt"));
	assert("rt\v[" ~ UN ~ "]\frt" == expandRange!(char)("rt[\\[\\]]rt"), 
		expandRange!(char)("rt[\\[\\]]rt"));
	assert("rt\va" ~ UN ~ "a\frt" == 
		expandRange!(char)("rt[aa]rt"), 
		stringWrite(expandRange!(char)("rt[aa]rt")));
	assert("rt\va" ~ UN ~ 'b' ~ UN ~ 'c' ~ UN ~ '[' ~ UN ~ ']' ~ "\frt" 
		== expandRange!(char)("rt[abc\\[\\]]rt"), 
		expandRange!(char)("rt[abc\\[\\]]rt"));
	assert("rt\v0"~UN~'1'~UN~'2'~UN~'3'~UN~'4'~UN~'5'~UN~'6'~UN~"7\frt" 
		== expandRange!(char)("rt[:odigit:]rt"), 
		expandRange!(char)("rt[:odigit:]rt"));
	assert("rt\v0"~UN~'1'~UN~"2\frt" == expandRange!(char)("rt[012]rt"), 
		expandRange!(char)("rt[012]rt"));
	assert("rt\va"~UN~'t'~UN~"h\frt" == expandRange!(char)("rt[ath]rt"), 
		expandRange!(char)("rt[ath]rt"));
	assert("rt\va"~UN~'t'~UN~"h\f[]rt" 
		== expandRange!(char)("rt[ath]\\[\\]rt"), 
		expandRange!(char)("rt[ath]\\[\\]rt"));

	bool rs = false;
	try {
		string a = expandRange!(char)("rt[021[12]]rt");
	} catch(Exception e) {
		rs = true;
	}
	assert(rs);
}
*/

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

/*
public immutable(T)[] expandRangeDirect(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	//writeln(__LINE__, " ",str);
	T[] upperChar = ['A','B','C','D','E','F','G','H','I','J','K','L',
		'M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
	assert(upperChar.length == 26);
	T[] lowChar = ['a','b','c','d','e','f','g','h','i','j','k','l',
		'm','n','o','p','q','r','s','t','u','v','w','x','y','z'];
	assert(lowChar.length == 26);
	T[] digits = ['0','1','2','3','4','5','6','7','8','9'];
	assert(digits.length == 10);
	T[] xdigits = ['A','B','C','D','E','F','0','1','2','3','4','5',
		'6','7','8','9','a','b','c','d','e','f'];
	assert(xdigits.length == 22);

	switch(str) {
		case ":alnum:": 
		case ":a-zA-Z0-9:":
			return ('\v' ~ setUnionSymbol!(T)(lowChar ~ upperChar ~ digits) 
				~ '\f').idup;
		case ":word:": 
		case ":a-zA-Z0-9_:":
			return ('\v' ~ setUnionSymbol!(T)(lowChar ~ upperChar ~ digits) 
				~ '_' ~ '\f').idup;
		case ":alpha:": 
		case ":a-zA-Z:":
			return ('\v' ~ setUnionSymbol!(T)(lowChar ~ upperChar) ~ '\f').idup;
		case ":a-z:":
			return ('\v' ~ setUnionSymbol!(T)(lowChar) ~ '\f').idup;
		case ":digit:": 
		case ":0-9:":
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
			return('\v' ~ setUnionSymbol!(T)(str.dup) ~ '\f').idup;
		}
	}
}

public immutable(T)[] concatExpand(T)(immutable(T)[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	//writeln(__LINE__, " ", str);
	str = expandRange!(T)(str);
	//writeln(__LINE__, " ", str);
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
*/
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
/*
unittest {
	assert("f\ad"~ST == concatExpand("fd*"), 
		concatExpand("fd*"));
	assert("f\ad"~ST~"\a\vt"~UN~"r\f\aw" == concatExpand("fd*[tr]w"), 
		stringWrite(concatExpand("fd*[tr]w")));
}
*/

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

public pure T[] aliases(T)(T[] str) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {
	//writeln(__LINE__, " ",str);
	T[] upperChar = ['A','B','C','D','E','F','G','H','I','J','K','L',
		'M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
	assert(upperChar.length == 26);
	T[] lowChar = ['a','b','c','d','e','f','g','h','i','j','k','l',
		'm','n','o','p','q','r','s','t','u','v','w','x','y','z'];
	assert(lowChar.length == 26);
	T[] digits = ['0','1','2','3','4','5','6','7','8','9'];
	assert(digits.length == 10);
	T[] xdigits = ['A','B','C','D','E','F','0','1','2','3','4','5',
		'6','7','8','9','a','b','c','d','e','f'];
	assert(xdigits.length == 22);

	switch(str) {
		case ":alnum:": 
		case ":a-zA-Z0-9:":
			return lowChar ~ upperChar ~ digits; 
		case ":word:": 
		case ":a-zA-Z0-9_:":
			return lowChar ~ upperChar ~ digits;
		case ":alpha:": 
		case ":a-zA-Z:":
			return lowChar ~ upperChar;
		case ":a-z:":
			return lowChar.dup;
		case ":digit:": 
		case ":0-9:":
			return digits.dup;
		case ":upper:":
			return upperChar.dup;
		case ":lower:":
			return lowChar.dup;
		case ":xdigit:":
			return xdigits.dup;
		case ":odigit:":
			return digits[0..8].dup;
		default: {
			assert(0);
		}
	}
}

private pure dchar[] unionExtend(dchar[] str) {
	dchar[] upperChar = ['A','B','C','D','E','F','G','H','I','J','K','L',
		'M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
	assert(upperChar.length == 26);
	dchar[] lowChar = ['a','b','c','d','e','f','g','h','i','j','k','l',
		'm','n','o','p','q','r','s','t','u','v','w','x','y','z'];
	assert(lowChar.length == 26);
	dchar[] digits = ['0','1','2','3','4','5','6','7','8','9'];
	assert(digits.length == 10);
	dchar[] xdigits = ['A','B','C','D','E','F','0','1','2','3','4','5',
		'6','7','8','9','a','b','c','d','e','f'];
	assert(xdigits.length == 22);

	dchar[] ret = new dchar[str.length*4];
	size_t ri = 0;

	for(size_t i = 0; i < str.length; i++) {
		if(str[i] == ':') {
			int nc = findColon!(dchar)(str,i+1);
			if(nc != -1) {
				assert(str[i] == ':');
				assert(str[nc] == ':', conv!(dchar,string)(str[nc]));
				dchar[] als = aliases!(dchar)(str[i .. nc+1]);					
				ri = appendWithIdx!(dchar)(ret, ri, als);
				i = nc;
			} else {
				appendWithIdx!(dchar)(ret, ri, cast(immutable)str[i]);
				ri++;
			}
		} else {
			appendWithIdx!(dchar)(ret, ri, cast(immutable)str[i]);
			ri++;
		}
	}
	return ret[0 .. ri];
}

unittest {
	assert("abc" == unionExtend("abc"d.dup));
	assert("0123456789abc"d == unionExtend(":digit:abc"d.dup), 
		conv!(dchar[],string)(unionExtend(":digit:abc"d.dup)));
	assert("0123456789abc0123456789" == 
		unionExtend(":digit:abc:digit:"d.dup), 
		conv!(dchar[],string)(unionExtend(":digit:abc:digit:"d.dup)));
}

public immutable(dchar)[] prepareString(immutable(dchar)[] str) {
	StringBuffer!(dchar) ret = new StringBuffer!(dchar)(str.length*3);	
	for(size_t i = 0; i < str.length; i++) {
		// writeln(i, " ", ret.getString());
		// in case you find the union char [ . 
		// Search till you find the matching ]
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
		} else if(str[i] == '+' && i > 0 && str[i-1] != '\\') {
			if(str[i-1] != ']') {
				ret.pushBack(str[i-1]);
			} else {
				size_t up = ret.getSize();
				size_t low = ret.getSize();
				while(ret.charAt(low) != '\v') {
					low--;
				}
				ret.pushBack(ret.getData()[low .. up]);
				ret.pushBack(ST);
				continue;
			}
			ret.pushBack(ST);
		} else if((str[i] == '[' && i > 0 && str[i-1] != '\\')
				|| (str[i] == '[' && i == 0)) {
			StringBuffer!(dchar) tmp = new StringBuffer!(dchar)();
			tmp.pushBack(str[i]);
			i++;
			while(i < str.length) {
				if(str[i] == ']' && i > 0 && str[i-1] != '\\') {
					tmp = tmp.pushBack(str[i]);
					break;
				} else if(str[i] == '[' && i > 0  && str[i-1] == '\\') {
					tmp.popBack();
					tmp.pushBack(str[i]);
					i++;
				} else if(str[i] == '[' && i > 0  && str[i-1] != '\\') {
					throw new ParseError("An [ inside an [ environment " ~
						"is useless str="~conv!(dstring,string)(str));
				} else if(str[i] == ']'  && i > 0 && str[i-1] == '\\') {
					tmp.popBack();
					tmp.pushBack(str[i]);
					i++;
				} else if(str[i] == '[' && i == 0) {
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
			ret.pushBack('\v');
			ret.pushBack(
				setUnionSymbol!(dchar)(unionExtend(tmp.getData()[1..$-1])));
			ret.pushBack('\f');
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
	assert("\v\f"d ~ ST == prepareString("[]*"d),
		conv!(dstring,string)(stringWrite!(dchar)(prepareString("[]*"d))));
	assert("\va\f"d ~ ST == prepareString("[a]*"d),
		conv!(dstring,string)(stringWrite!(dchar)(prepareString("[a]*"d))));
	assert("\va\f\va\f"d ~ ST == prepareString("[a]+"d),
		conv!(dstring,string)(stringWrite!(dchar)(prepareString("[a]+"d))));
	assert("aa"d ~ ST == prepareString("a+"d),
		conv!(dstring,string)(stringWrite!(dchar)(prepareString("a+"d))));
	assert("\v\f" == prepareString("[]"d), 
		conv!(dstring,string)(prepareString("[]"d)));
	assert("rt\v\frt" == prepareString("rt[]rt"d), 
		conv!(dstring,string)(prepareString("rt[]rt"d)));
	assert("rt\v\f\v\f"d ~ ST ~ "rt" == prepareString("rt[]+rt"d), 
		conv!(dstring,string)(prepareString("rt[]rt+"d)));
	assert("rt[]rt" == prepareString("rt\\[\\]rt"d), 
		conv!(dstring,string)(prepareString("rt\\[\\]rt"d)));
	assert("rt\v["d ~ UN ~ "]\frt"d == prepareString("rt[\\[\\]]rt"d), 
		conv!(dstring,string)(prepareString("rt[\\[\\]]rt"d)));
	assert("rt\va"d ~ UN ~ "a\frt"d == 
		prepareString("rt[aa]rt"d), 
		conv!(dstring,string)(stringWrite(prepareString("rt[aa]rt"d))));
	assert("rt\va"d ~ UN ~ 'b' ~ UN ~ 'c' ~ UN ~ '[' ~ UN ~ ']' ~ "\frt"d 
		== prepareString("rt[abc\\[\\]]rt"d), 
		conv!(dstring,string)(prepareString("rt[abc\\[\\]]rt"d)));
	assert("rt\v0"d~UN~'1'~UN~'2'~UN~'3'~UN~'4'~UN~'5'~UN~'6'~UN~"7\frt"d 
		== prepareString("rt[:odigit:]rt"d), 
		conv!(dstring,string)(prepareString("rt[:odigit:]rt"d)));
	assert("rt\v0"d~UN~'1'~UN~'2'~UN~'3'~UN~'4'~UN~'5'~UN~'6'~UN~"7\f" ~ 
		"\v0"d~UN~'1'~UN~'2'~UN~'3'~UN~'4'~UN~'5'~UN~'6'~UN~"7\f" ~ ST ~ "rt"d 
		== prepareString("rt[:odigit:]+rt"d), 
		conv!(dstring,string)(prepareString("rt[:odigit:]+rt"d)));
	assert("rt\v0"d~UN~'1'~UN~"2\frt"d == prepareString("rt[012]rt"d), 
		conv!(dstring,string)(prepareString("rt[012]rt"d)));
	assert("rt\va"d~UN~'t'~UN~"h\frt"d == prepareString("rt[ath]rt"d), 
		conv!(dstring,string)(prepareString("rt[ath]rt"d)));
	assert("rt\va"d~UN~'t'~UN~"h\f[]rt"d 
		== prepareString("rt[ath]\\[\\]rt"d), 
		conv!(dstring,string)(prepareString("rt[ath]\\[\\]rt"d)));

	bool rs = false;
	try {
		dstring a = prepareString("rt[021[12]]rt"d);
	} catch(Exception e) {
		rs = true;
	}
	assert(rs);
	
}

private pure int findColon(T)(in T[] str, size_t start = 0) 
		if(is(T == char) || is(T == wchar) || is(T == dchar)) {

	int ret = -1;
	if(start < 0) {
		return ret;
	} else if(str.length < 1) {
		return ret;
	} else if(start >= str.length) {
		return ret;
	}

	ret = 0;
	foreach(idx, it; str[start..$]) {
		if(it == ':') {
			return conv!(size_t,int)(ret+start);	
		}
		ret++;	
		assert(ret-1 == idx, conv!(int,string)(ret-1) ~ " != " ~ 
			conv!(size_t,string)(idx));
	}
	return -1;
}

unittest {
	assert(-1 == findColon!(char)("      "));
	assert(-1 != findColon!(char)(" :    "));
	assert(1 == findColon!(char)(" :    ",1), 
		conv!(int,string)(findColon!(char)(" :    ",1)));
	assert(4 == findColon!(char)("    : ",1));
	assert(4 == findColon!(char)("    : ",3));
	assert(4 == findColon!(char)("    : ",4));
	assert(5 == findColon!(char)("     :",1));
	assert(5 == findColon!(char)("     :",3));
	assert(5 == findColon!(char)("     :",4));
	assert(5 == findColon!(char)("     :",5));
	assert(0 == findColon!(char)(":     "));
	assert(-1 == findColon!(char)(":     ",1));
	assert(0 == findColon!(char)(":     ",0));
	assert(3 == findColon!(char)("   :  ",3));
}

public pure int userCodeParanthesis(in char[] str, int start = 0) {
	int ret = -1;
	if(start < 0) {
		return ret;
	} else if(str.length < 2) {
		return ret;
	} else if(start >= str.length) {
		return ret;
	} else if(start == str.length-1) {
		return ret;
	}

	ret = 0;
	foreach(idx, it; str[start..$-1]) {
		if(it == '%' && str[start+idx+1] == '%') {
			return ret+start;	
		}
		ret++;	
		assert(ret-1 == idx, conv!(int,string)(ret-1) ~ " != " ~ 
			conv!(size_t,string)(idx));
	}
	return -1;
}

public int userCodeBrace(bool dir)(in char[] str, int start = 0) {
	if(start < 0) {
		return -1;
	} else if(str.length < 1)
		return -1;
	else if(start >= str.length)
		return -1;
	else if(start == str.length)
		return -1;

	static if(!dir) {
		foreach(idx, it; str[start..$-1]) {
			if(it == '{' && str[idx+start+1] == ':') {
				return conv!(size_t,int)(idx)+start;	
			} else if(!(it == ' ' || it == '\t')) {
				return -1;
			}
		}
	} else {
		foreach_reverse(idx, it; str[start+1..$]) {
			if(it == '}' && str[start+idx] == ':') {
				return conv!(size_t,int)(idx)+start;	
			} else if(!(it == ' ' || it == '\t')) {
				return -1;
			}
		}
	}
	return -1;
}

unittest {
	assert(-1 != userCodeBrace!(false)("   {:"));
	assert(3 == userCodeBrace!(false)("   {:"));
	assert(3 == userCodeBrace!(false)("   {:",2));
	assert(-1 == userCodeBrace!(false)("    "));
	assert(-1 == userCodeBrace!(false)("%    %"));
	assert(-1 != userCodeBrace!(false)("{:  %%"));
	assert(0 == userCodeBrace!(false)("{:  %%"));
	assert(-1 == userCodeBrace!(true)("  }:%%"));
	assert(-1 == userCodeBrace!(true)("  %%"));
	assert(-1 != userCodeBrace!(true)("%%  %:}"));
	assert(-1 != userCodeBrace!(true)("%%  %:}", 3));
	assert(-1 != userCodeBrace!(true)("%%  %:} "));
	assert(-1 != userCodeBrace!(true)("%%  %:}  ", 3));
	assert(-1 == userCodeBrace!(true)("%%  %:} t"));
	assert(-1 == userCodeBrace!(true)("%%  %:} ]", 3));
	assert(5 == userCodeBrace!(true)("%%  %:}", 3), 
		conv!(int,string)(userCodeBrace!(true)("%%  %:}", 3)));
	assert(-1 == userCodeBrace!(true)("%%  :}%", 6));
	assert(-1 == userCodeBrace!(true)("%%:}  %", 3));
}

public pure int findTick(in char[] str, int start = 0) {
	int ret = -1;
	if(start < 0) {
		return ret;
	} else if(str.length < 2) {
		return ret;
	} else if(start >= str.length) {
		return ret;
	} else if(start == str.length-1) {
		return ret;
	}

	ret = 0;
	foreach(idx, it; str[start..$]) {
		if(it == '"' && idx+start == 0) {
			return ret;	
		} else if(it == '"' && (idx > 0 || start > 0) 
				&& str[idx+start-1] != '\\') {
			return ret+start;
		}
		ret++;	
		assert(ret-1 == idx, conv!(int,string)(ret-1) ~ " != " ~ 
			conv!(size_t,string)(idx));
	}
	return -1;
}
unittest {
	assert(-1 != findTick([' ', ' ','"']), 
		conv!(int,string)(findTick([' ', ' ','"'])));
	assert(2 == findTick([' ', ' ','"']), 
		conv!(int,string)(findTick([' ', ' ','"'])));
	assert(-1 == findTick([' ', '\\','"']), 
		conv!(int,string)(findTick([' ', '\\','"'])));
	assert(-1 != findTick([' ', ' ',' ', ' ','"']), 
		conv!(int,string)(findTick([' ', ' ',' ', ' ','"'])));
	assert(4 == findTick([' ', ' ',' ', ' ','"']), 
		conv!(int,string)(findTick([' ', ' ',' ', ' ','"'])));
	assert(-1 != findTick([' ', ' ',' ', ' ','"'],2), 
		conv!(int,string)(findTick([' ', ' ',' ', ' ','"'],2)));
	assert(4 == findTick([' ', ' ',' ', ' ','"'],2), 
		conv!(int,string)(findTick([' ', ' ',' ', ' ','"'],2)));
	assert(-1 != findTick(['"', ' ',' ', ' ','"'],0), 
		conv!(int,string)(findTick([' ', ' ',' ', ' ','"'],0)));
	assert(0 == findTick(['"', ' ',' ', ' ','"'],0), 
		conv!(int,string)(findTick([' ', ' ',' ', ' ','"'],0)));
}

unittest {
	assert(-1 != userCodeParanthesis("   %%"));
	assert(3 == userCodeParanthesis("   %%"));
	assert(-1 == userCodeParanthesis("   %"));
	assert(-1 == userCodeParanthesis("%  % %"));
	assert(-1 != userCodeParanthesis("%  %%"));
	assert(3 == userCodeParanthesis("%  %%"));
	assert(-1 != userCodeParanthesis("%%  %%"));
	assert(0 == userCodeParanthesis("%%  %%"));
	assert(-1 != userCodeParanthesis("%%  %%", 3));
	assert(4 == userCodeParanthesis("%%  %%", 3), 
		conv!(int,string)(userCodeParanthesis("%%  %%", 3)));
	assert(-1 == userCodeParanthesis("%%  %%", 5));
}
