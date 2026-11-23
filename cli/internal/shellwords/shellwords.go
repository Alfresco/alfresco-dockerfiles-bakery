// Package shellwords splits strings into words the way a POSIX shell does,
// without any expansion.
package shellwords

import (
	"errors"
	"strings"
)

// Split splits s on unquoted whitespace. Double quotes group words and allow
// backslash escapes, a backslash outside quotes escapes the next character,
// and with singleQuotes set single quotes group words literally.
func Split(s string, singleQuotes bool) ([]string, error) {
	var words []string
	var word strings.Builder
	inWord := false
	var quote rune
	escaped := false
	for _, r := range s {
		switch {
		case escaped:
			word.WriteRune(r)
			escaped = false
		case quote == '\'':
			if r == '\'' {
				quote = 0
			} else {
				word.WriteRune(r)
			}
		case quote == '"':
			switch r {
			case '"':
				quote = 0
			case '\\':
				escaped = true
			default:
				word.WriteRune(r)
			}
		case r == '\\':
			escaped, inWord = true, true
		case r == '"' || (r == '\'' && singleQuotes):
			quote, inWord = r, true
		case r == ' ' || r == '\t' || r == '\n' || r == '\r':
			if inWord {
				words = append(words, word.String())
				word.Reset()
				inWord = false
			}
		default:
			word.WriteRune(r)
			inWord = true
		}
	}
	if quote != 0 {
		return nil, errors.New("unclosed quote in " + s)
	}
	if escaped {
		word.WriteRune('\\')
	}
	if inWord {
		words = append(words, word.String())
	}
	return words, nil
}
