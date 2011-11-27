module dex.parseerror;

import hurt.string.formatter;

/// Parse Error Exception
class ParseError : Exception {
	this(string str, string file = __FILE__, int line = __LINE__) {
		super(format("%s:%d %s", file, line, str));
	}
}
