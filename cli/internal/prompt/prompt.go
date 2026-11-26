// Package prompt asks the user yes/no questions.
package prompt

import (
	"bufio"
	"io"
	"strings"
)

// Confirm reads one answer line and reports whether it starts with y or Y.
// End of input counts as no.
func Confirm(in io.Reader) bool {
	line, _ := bufio.NewReader(in).ReadString('\n')
	line = strings.TrimSpace(line)
	return line != "" && (line[0] == 'y' || line[0] == 'Y')
}
