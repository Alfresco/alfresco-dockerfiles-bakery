// Package shellwords splits strings into words the way a POSIX shell or a
// .netrc file does, without any expansion.
package shellwords

import (
	"errors"
	"strings"
)

type Mode int

const (
	// Shell follows POSIX quoting: single quotes are literal, and inside double
	// quotes a backslash only escapes \ " $ ` and newline.
	Shell Mode = iota
	// Netrc follows .netrc quoting: only double quotes group, a backslash
	// always escapes the next character, and a word starting with # begins a
	// comment that runs to the end of the line.
	Netrc
)

var errUnclosedQuote = errors.New("unclosed quote")

// Split splits s on unquoted whitespace according to mode.
func Split(s string, mode Mode) ([]string, error) {
	var words []string
	var word strings.Builder
	inWord := false
	var quote rune
	escaped := false
	for _, r := range s {
		switch {
		case escaped:
			if quote == '"' && mode == Shell && !strings.ContainsRune("\\\"$`\n", r) {
				word.WriteRune('\\')
			}
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
		case r == '"' || (r == '\'' && mode == Shell):
			quote, inWord = r, true
		case r == ' ' || r == '\t' || r == '\n' || r == '\r':
			if inWord {
				words = append(words, word.String())
				word.Reset()
				inWord = false
			}
		case r == '#' && mode == Netrc && !inWord:
			return words, nil
		default:
			word.WriteRune(r)
			inWord = true
		}
	}
	if quote != 0 {
		return nil, errUnclosedQuote
	}
	if escaped {
		word.WriteRune('\\')
	}
	if inWord {
		words = append(words, word.String())
	}
	return words, nil
}
