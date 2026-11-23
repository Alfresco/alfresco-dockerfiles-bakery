// Package logx is a small leveled logger writing plain messages to the
// console and timestamped messages to an optional log file.
package logx

import (
	"fmt"
	"io"
	"os"
	"strings"
	"time"
)

type Level int

const (
	Debug Level = iota
	Info
	Warning
	Error
)

func ParseLevel(s string) (Level, error) {
	switch strings.ToUpper(s) {
	case "DEBUG":
		return Debug, nil
	case "INFO", "":
		return Info, nil
	case "WARNING":
		return Warning, nil
	case "ERROR":
		return Error, nil
	}
	return Info, fmt.Errorf("invalid log level %q (DEBUG, INFO, WARNING, ERROR)", s)
}

type Logger struct {
	out   io.Writer
	file  *os.File
	level Level
}

// New returns a logger writing to out, and also to logFile when it is not empty.
func New(out io.Writer, level Level, logFile string) (*Logger, error) {
	l := &Logger{out: out, level: level}
	if logFile != "" {
		f, err := os.OpenFile(logFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o600)
		if err != nil {
			return nil, err
		}
		l.file = f
	}
	return l, nil
}

func (l *Logger) Close() error {
	if l.file != nil {
		return l.file.Close()
	}
	return nil
}

func (l *Logger) log(level Level, name, format string, args ...any) {
	if level < l.level {
		return
	}
	msg := fmt.Sprintf(format, args...)
	stamped := fmt.Sprintf("%s - %s: %s\n", time.Now().Format("2006-01-02 15:04:05"), name, msg)
	if l.level == Debug {
		fmt.Fprint(l.out, stamped)
	} else {
		fmt.Fprintln(l.out, msg)
	}
	if l.file != nil {
		fmt.Fprint(l.file, stamped)
	}
}

func (l *Logger) Debugf(format string, args ...any) { l.log(Debug, "DEBUG", format, args...) }
func (l *Logger) Infof(format string, args ...any)  { l.log(Info, "INFO", format, args...) }
func (l *Logger) Warnf(format string, args ...any)  { l.log(Warning, "WARNING", format, args...) }
func (l *Logger) Errorf(format string, args ...any) { l.log(Error, "ERROR", format, args...) }
