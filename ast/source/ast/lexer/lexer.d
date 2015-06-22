module ast.lexer.lexer;

import ast.lexer.exception;
import ast.lexer.token;
import des.log;
import std.container;
import std.regex;
import std.array;

class Lexer {
public:
	this(string data) {
		this.data = data.replace("\t", " "); //TODO: Fix this silly hack for GetDataPos
		process();
	}
	
	@property string Data() { return data; }
	@property Array!Token Tokens() { return tokens; } 
	
	size_t[2] GetLinePos(size_t index) {
		size_t row = 0;
		size_t column = 0;
		
		if (index >= data.length)
			return [-1, -1];
		
		//Calculate the row and column number for the index
		for (size_t i = 0; i < index; i++)
			if (data[i] == '\n') {
				row++;
				column = 0;
			} else 
				column++;
			
		return [row, column];
	}

	size_t GetDataPos(size_t[2] pos) {
		size_t row = 0;
		size_t column = 0;
		import std.stdio;		
		//Calculate the row and column number for the index
		for (size_t i = 0; i < data.length; i++) {
			if (row == pos[0] && column == pos[1])
				return i;
			else if (row > pos[0]) {
				writefln("\nMoved past the point: %s, i: %s, row: %s, column: %s", pos, i, row, column);
				return -1;
			}

			if (data[i] == '\n') {
				row++;
				column = 0;
			} else 
				column++;
		}

		writefln("\nPos is out of file: %s", pos);
		return -1;
	}
	
private:
	string data;
	Array!Token tokens;
	
	size_t current;
	
	void process() {
		import std.stdio;
		logger.info("Start with lexing!");
		size_t lastCurrent = current;
		while (current < data.length) {
			lastCurrent = current;
			write("\rCurrent token: ", current + 1, " out of ", data.length);
			parseToken();
			if (current == lastCurrent) {
				logger.error("\rFailed to parse token ", current + 1, " --> '", data[current], "'");
				break;
			}
		}
		writeln();
		logger.info("End of lexing!");
	}
	
	void parseToken() {
		if (skipWhitespace()) {}
		else if (skipComments()) {}
		else if (addOperator()) {}
		else if (addAttribute()) {}
		else if (addType()) {}
		else if (addKeyword()) {}
		else if (addValue()) {}
		else if (addSymbol()) {}
		else
			throw new InvalidTokenException(this, current, data.length - 1);
	}

	bool add(alias re, T, args...)(args arg) {
		auto result = matchFirst(data[current..$], ctRegex!("^"~re));
		if (result.empty)
			return false;
		
		tokens ~= new T(this, current, current + result[0].length, arg);
		current += result[0].length;
		return true;
	}

	bool addKeyword(alias re, T, args...)(string text, args arg) {
		if (text != re)
			return false;

		tokens ~= new T(this, current, current + text.length, arg);
		current += text.length;
		return true;
	}
	
	bool skipWhitespace() {
		import core.stdc.ctype;
		if (!data[current].isspace)
			return false;
		while (current < data.length && data[current].isspace)
			current++;
		return true;
	}

	bool skipComments() {
		auto result = matchFirst(data[current..$], ctRegex!(`^//[^\n]*`));
		if (result.empty) {
			result = matchFirst(data[current..$], ctRegex!(`^/\*[^(\*/)]*\*/`));
			if (result.empty)
				return false;
		}

		current += result[0].length;
		return true;
	}

	bool addOperator() {
		if (add!(`\{`, OperatorToken)(OperatorType.CURLYBRACKET_OPEN)) {}
		else if (add!(`\}`, OperatorToken)(OperatorType.CURLYBRACKET_CLOSE)) {}
		else if (add!(`\(`, OperatorToken)(OperatorType.BRACKET_OPEN)) {}
		else if (add!(`\)`, OperatorToken)(OperatorType.BRACKET_CLOSE)) {}
		else if (add!(`\[`, OperatorToken)(OperatorType.SQUAREBRACKET_OPEN)) {}
		else if (add!(`\]`, OperatorToken)(OperatorType.SQUAREBRACKET_CLOSE)) {}
		else if (add!(`\+`, OperatorToken)(OperatorType.PLUS)) {}
		else if (add!(`-`, OperatorToken)(OperatorType.MINUS)) {}
		else if (add!(`\*`, OperatorToken)(OperatorType.ASTERISK)) {}
		else if (add!(`/`, OperatorToken)(OperatorType.SLASH)) {}
		else if (add!(`\.`, OperatorToken)(OperatorType.DOT)) {}
		else if (add!(`==`, OperatorToken)(OperatorType.EQUALS)) {}
		else if (add!(`=`, OperatorToken)(OperatorType.ASSIGN)) {}
		else if (add!(`\+\+`, OperatorToken)(OperatorType.INCREMENT)) {}
		else if (add!(`--`, OperatorToken)(OperatorType.DECREMENT)) {}
		else if (add!(`\+=`, OperatorToken)(OperatorType.ADD_ASSIGN)) {}
		else if (add!(`-=`, OperatorToken)(OperatorType.SUB_ASSIGN)) {}
		else if (add!(`\*=`, OperatorToken)(OperatorType.MUL_ASSIGN)) {}
		else if (add!(`/=`, OperatorToken)(OperatorType.DIV_ASSIGN)) {}
		else if (add!(`<<=`, OperatorToken)(OperatorType.LEFT_SHIFT_ASSIGN)) {}
		else if (add!(`>>=`, OperatorToken)(OperatorType.RIGHT_SHIFT_ASSIGN)) {}
		else if (add!(`<<<=`, OperatorToken)(OperatorType.LEFT_ROTATE_ASSIGN)) {}
		else if (add!(`>>>=`, OperatorToken)(OperatorType.RIGHT_ROTATE_ASSIGN)) {}
		else if (add!(`<<<`, OperatorToken)(OperatorType.LEFT_ROTATE)) {}
		else if (add!(`>>>`, OperatorToken)(OperatorType.RIGHT_ROTATE)) {}
		else if (add!(`<<`, OperatorToken)(OperatorType.LEFT_SHIFT)) {}
		else if (add!(`>>`, OperatorToken)(OperatorType.RIGHT_SHIFT)) {}
		else if (add!(`<=`, OperatorToken)(OperatorType.LESS_THAN_EQUAL)) {}
		else if (add!(`>=`, OperatorToken)(OperatorType.GREATER_THAN_EQUAL)) {}
		else if (add!(`<`, OperatorToken)(OperatorType.LESS_THAN)) {}
		else if (add!(`>`, OperatorToken)(OperatorType.GREATER_THAN)) {}
		else if (add!(`&=`, OperatorToken)(OperatorType.BIT_AND_ASSIGN)) {}
		else if (add!(`&&=`, OperatorToken)(OperatorType.LOG_AND_ASSIGN)) {}
		else if (add!(`&&`, OperatorToken)(OperatorType.DOUBLE_AND)) {}
		else if (add!(`&`, OperatorToken)(OperatorType.BIT_AND)) {}
		else if (add!(`\|=`, OperatorToken)(OperatorType.BIT_OR_ASSIGN)) {}
		else if (add!(`\|\|=`, OperatorToken)(OperatorType.LOG_OR_ASSIGN)) {}
		else if (add!(`\|\|`, OperatorToken)(OperatorType.LOG_OR)) {}
		else if (add!(`\|`, OperatorToken)(OperatorType.BIT_OR)) {}
		else if (add!(`\^=`, OperatorToken)(OperatorType.BIT_XOR_ASSIGN)) {}
		else if (add!(`\^\^=`, OperatorToken)(OperatorType.LOG_XOR_ASSIGN)) {}
		else if (add!(`\^\^`, OperatorToken)(OperatorType.LOG_XOR)) {}
		else if (add!(`\^`, OperatorToken)(OperatorType.BIT_XOR)) {}
		else if (add!(`,`, OperatorToken)(OperatorType.COMMA)) {}
		else if (add!(`%=`, OperatorToken)(OperatorType.MODULO_ASSIGN)) {}
		else if (add!(`%`, OperatorToken)(OperatorType.MODULO)) {}
		else if (add!(`!=`, OperatorToken)(OperatorType.NOT_EQUALS)) {}
		else if (add!(`!`, OperatorToken)(OperatorType.LOG_NOT)) {}
		else if (add!(`~=`, OperatorToken)(OperatorType.BIT_NOT_ASSIGN)) {}
		else if (add!(`~`, OperatorToken)(OperatorType.BIT_NOT)) {}
		else if (add!(`\.\.\.`, OperatorToken)(OperatorType.VARIADIC)) {}
		else if (add!(`:`, OperatorToken)(OperatorType.COLON)) {}
		else if (add!(`\?`, OperatorToken)(OperatorType.QUESTIONMARK)) {}

		else if (add!(`;`, EndToken)()) {}
		else
			return false;
		return true;
	}

	bool addAttribute() {
		if (add!(`^@[\p{L}_][\p{L}_0123456789]*`, AttributeToken)(AttributeType.SPECIAL)) {}
		else {
			auto result = matchFirst(data[current..$], ctRegex!(`^[\p{L}_][\p{L}_0123456789]*`));
			if (result.empty)
				return false;
			auto text = result[0];

			if (addKeyword!(`lazy`, AttributeToken)(text, AttributeType.LAZY)) {}

			else if (addKeyword!(`const`, AttributeToken)(text, AttributeType.CONST)) {}
			else if (addKeyword!(`static`, AttributeToken)(text, AttributeType.STATIC)) {}

			else if (addKeyword!(`public`, AttributeToken)(text, AttributeType.PUBLIC)) {}
			else if (addKeyword!(`private`, AttributeToken)(text, AttributeType.PRIVATE)) {}
			else if (addKeyword!(`protected`, AttributeToken)(text, AttributeType.PROTECTED)) {}
			else
				return false;
		}
		return true;
	}

	bool addType() {
		auto result = matchFirst(data[current..$], ctRegex!(`^[\p{L}_][\p{L}_0123456789]*`));
		if (result.empty)
			return false;
		auto text = result[0];
		
		if (addKeyword!(`auto`, TypeToken)(text, TypeType.AUTO)) {}
		
		else if (addKeyword!(`bool`, TypeToken)(text, TypeType.BOOL)) {}
		
		else if (addKeyword!(`byte`, TypeToken)(text, TypeType.BYTE)) {}
		else if (addKeyword!(`ubyte`, TypeToken)(text, TypeType.UBYTE)) {}
		else if (addKeyword!(`short`, TypeToken)(text, TypeType.SHORT)) {}
		else if (addKeyword!(`ushort`, TypeToken)(text, TypeType.USHORT)) {}
		else if (addKeyword!(`int`, TypeToken)(text, TypeType.INT)) {}
		else if (addKeyword!(`uint`, TypeToken)(text, TypeType.UINT)) {}
		else if (addKeyword!(`long`, TypeToken)(text, TypeType.LONG)) {}
		else if (addKeyword!(`ulong`, TypeToken)(text, TypeType.ULONG)) {}
		else if (addKeyword!(`float`, TypeToken)(text, TypeType.FLOAT)) {}
		else if (addKeyword!(`double`, TypeToken)(text, TypeType.DOUBLE)) {}
		
		else if (addKeyword!(`string`, TypeToken)(text, TypeType.STRING)) {}
		else
			return false;
		return true;
	}

	bool addKeyword() {
		auto result = matchFirst(data[current..$], ctRegex!(`^[\p{L}_][\p{L}_0123456789]*`));
		if (result.empty)
			return false;
		auto text = result[0];

		if (addKeyword!(`if`, KeywordToken)(text, KeywordType.IF)) {}
		else if (addKeyword!(`else`, KeywordToken)(text, KeywordType.ELSE)) {}
		else if (addKeyword!(`for`, KeywordToken)(text, KeywordType.FOR)) {}
		else if (addKeyword!(`while`, KeywordToken)(text, KeywordType.WHILE)) {}
		else if (addKeyword!(`do`, KeywordToken)(text, KeywordType.DO)) {}
		else if (addKeyword!(`return`, KeywordToken)(text, KeywordType.RETURN)) {}
		else if (addKeyword!(`break`, KeywordToken)(text, KeywordType.BREAK)) {}
		else if (addKeyword!(`switch`, KeywordToken)(text, KeywordType.SWITCH)) {}
		else if (addKeyword!(`default`, KeywordToken)(text, KeywordType.DEFAULT)) {}
		else if (addKeyword!(`case`, KeywordToken)(text, KeywordType.CASE)) {}
		
		else if (addKeyword!(`class`, KeywordToken)(text, KeywordType.CLASS)) {}
		else if (addKeyword!(`data`, KeywordToken)(text, KeywordType.DATA)) {}
		else if (addKeyword!(`alias`, KeywordToken)(text, KeywordType.ALIAS)) {}

		else if (addKeyword!(`cast`, KeywordToken)(text, KeywordType.CAST)) {}

		else if (addKeyword!(`module`, KeywordToken)(text, KeywordType.MODULE)) {}
		else if (addKeyword!(`import`, KeywordToken)(text, KeywordType.IMPORT)) {}
		
		else
			return false;
		return true;
	}

	bool addValue() {
		if (add!(`true`, ValueToken)(ValueType.TRUE)) {}
		else if (add!(`false`, ValueToken)(ValueType.FALSE)) {}

		else if (add!(`[\+-]?0[1-7][0-7]*`, ValueToken)(ValueType.OCTALINT)) {}
		else if (add!(`[\+-]?0[1-7][0-7]*l`, ValueToken)(ValueType.OCTALLONG)) {}

		else if (add!(`[\+-]?0x[\dabcdefABCDEF]+`, ValueToken)(ValueType.HEXINT)) {}
		else if (add!(`[\+-]?0x[\dabcdef]+l`, ValueToken)(ValueType.HEXLONG)) {}

		else if (add!(`[\+-]?0b[01]+`, ValueToken)(ValueType.BINARYINT)) {}
		else if (add!(`[\+-]?0b[01]+l`, ValueToken)(ValueType.BINARYLONG)) {}

		else if (add!(`[\+-]?(\d*\.\d+|\d+\.\d*|\d+)f`, ValueToken)(ValueType.FLOAT)) {}
		else if (add!(`[\+-]?(\d*\.\d+|\d+\.\d*)`, ValueToken)(ValueType.DOUBLE)) {}

		else if (add!(`[\+-]?\d+b`, ValueToken)(ValueType.INT)) {}
		else if (add!(`\+?\d+ub`, ValueToken)(ValueType.UINT)) {}
		else if (add!(`[\+-]?\d+s`, ValueToken)(ValueType.SHORT)) {}
		else if (add!(`\+?\d+us`, ValueToken)(ValueType.USHORT)) {}
		else if (add!(`[\+-]?\d+i?`, ValueToken)(ValueType.INT)) {}
		else if (add!(`\+?\d+ui?`, ValueToken)(ValueType.UINT)) {}
		else if (add!(`[\+-]?\d+l`, ValueToken)(ValueType.LONG)) {}
		else if (add!(`\+?\d+ul`, ValueToken)(ValueType.ULONG)) {}

		else if (add!(`"([^"]|\\")*"`, ValueToken)(ValueType.STRING)) {}

		else
			return false;
		return true;
	}

	bool addSymbol() {
		enum blocks = `\p{L}` ~
//`\p{InBasic_Latin}` ~
`\p{InLatin-1_Supplement}` ~
`\p{InLatin_Extended-A}` ~
`\p{InLatin_Extended-B}` ~
`\p{InIPA_Extensions}` ~
`\p{InSpacing_Modifier_Letters}` ~
`\p{InCombining_Diacritical_Marks}` ~
`\p{InGreek_and_Coptic}` ~
`\p{InCyrillic}` ~
//`\p{InCyrillic_Supplementary}` ~
`\p{InArmenian}` ~
`\p{InHebrew}` ~
`\p{InArabic}` ~
`\p{InSyriac}` ~
`\p{InThaana}` ~
`\p{InDevanagari}` ~
`\p{InBengali}` ~
`\p{InGurmukhi}` ~
`\p{InGujarati}` ~
`\p{InOriya}` ~
`\p{InTamil}` ~
`\p{InTelugu}` ~
`\p{InKannada}` ~
`\p{InMalayalam}` ~
`\p{InSinhala}` ~
`\p{InThai}` ~
`\p{InLao}` ~
`\p{InTibetan}` ~
`\p{InMyanmar}` ~
`\p{InGeorgian}` ~
`\p{InHangul_Jamo}` ~
`\p{InEthiopic}` ~
`\p{InCherokee}` ~
`\p{InUnified_Canadian_Aboriginal_Syllabics}` ~
`\p{InOgham}` ~
`\p{InRunic}` ~
`\p{InTagalog}` ~
`\p{InHanunoo}` ~
`\p{InBuhid}` ~
`\p{InTagbanwa}` ~
`\p{InKhmer}` ~
`\p{InMongolian}` ~
`\p{InLimbu}` ~
`\p{InTai_Le}` ~
`\p{InKhmer_Symbols}` ~
`\p{InPhonetic_Extensions}` ~
`\p{InLatin_Extended_Additional}` ~
`\p{InGreek_Extended}` ~
//`\p{InGeneral_Punctuation}` ~
`\p{InSuperscripts_and_Subscripts}` ~
`\p{InCurrency_Symbols}` ~
`\p{InCombining_Diacritical_Marks_for_Symbols}` ~
`\p{InLetterlike_Symbols}` ~
`\p{InNumber_Forms}` ~
`\p{InArrows}` ~
`\p{InMathematical_Operators}` ~
`\p{InMiscellaneous_Technical}` ~
`\p{InControl_Pictures}` ~
`\p{InOptical_Character_Recognition}` ~
`\p{InEnclosed_Alphanumerics}` ~
`\p{InBox_Drawing}` ~
`\p{InBlock_Elements}` ~
`\p{InGeometric_Shapes}` ~
`\p{InMiscellaneous_Symbols}` ~
`\p{InDingbats}` ~
`\p{InMiscellaneous_Mathematical_Symbols-A}` ~
`\p{InSupplemental_Arrows-A}` ~
`\p{InBraille_Patterns}` ~
`\p{InSupplemental_Arrows-B}` ~
`\p{InMiscellaneous_Mathematical_Symbols-B}` ~
`\p{InSupplemental_Mathematical_Operators}` ~
`\p{InMiscellaneous_Symbols_and_Arrows}` ~
`\p{InCJK_Radicals_Supplement}` ~
`\p{InKangxi_Radicals}` ~
`\p{InIdeographic_Description_Characters}` ~
`\p{InCJK_Symbols_and_Punctuation}` ~
`\p{InHiragana}` ~
`\p{InKatakana}` ~
`\p{InBopomofo}` ~
`\p{InHangul_Compatibility_Jamo}` ~
`\p{InKanbun}` ~
`\p{InBopomofo_Extended}` ~
`\p{InKatakana_Phonetic_Extensions}` ~
`\p{InEnclosed_CJK_Letters_and_Months}` ~
`\p{InCJK_Compatibility}` ~
`\p{InCJK_Unified_Ideographs_Extension_A}` ~
`\p{InYijing_Hexagram_Symbols}` ~
`\p{InCJK_Unified_Ideographs}` ~
`\p{InYi_Syllables}` ~
`\p{InYi_Radicals}` ~
`\p{InHangul_Syllables}` ~
`\p{InHigh_Surrogates}` ~
`\p{InHigh_Private_Use_Surrogates}` ~
`\p{InLow_Surrogates}` ~
`\p{InPrivate_Use_Area}` ~
`\p{InCJK_Compatibility_Ideographs}` ~
`\p{InAlphabetic_Presentation_Forms}` ~
`\p{InArabic_Presentation_Forms-A}` ~
`\p{InVariation_Selectors}` ~
`\p{InCombining_Half_Marks}` ~
`\p{InCJK_Compatibility_Forms}` ~
`\p{InSmall_Form_Variants}` ~
`\p{InArabic_Presentation_Forms-B}` ~
`\p{InHalfwidth_and_Fullwidth_Forms}` ~
`\p{InSpecials}`;
		auto result = matchFirst(data[current..$], ctRegex!(`^[`~blocks~`_][`~blocks~`_0123456789]*`));
		if (result.empty)
			return false;
		tokens ~= new SymbolToken(this, current, current + result[0].length);
		current += result[0].length;
		return true;
	}
}

