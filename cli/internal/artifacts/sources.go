package artifacts

import (
	"bufio"
	"errors"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"gopkg.in/yaml.v3"

	"github.com/Alfresco/alfresco-dockerfiles-bakery/cli/internal/shellwords"
)

type source struct {
	name     string
	url      string
	username string
	password string
}

func (f *Fetcher) loadSources() (map[string]*source, error) {
	path := f.SourcesFile
	if path == "" {
		path = filepath.Join(f.Root, "sources.yaml")
	}
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, fmt.Errorf("sources file not found: %s", path)
	} else if err != nil {
		return nil, err
	}
	var doc struct {
		Sources map[string]struct {
			URL string `yaml:"url"`
		} `yaml:"sources"`
	}
	if err := yaml.Unmarshal(data, &doc); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	if len(doc.Sources) == 0 {
		return nil, fmt.Errorf("no sources defined in %s", path)
	}

	creds, err := readNetrc(f.netrcPath())
	if err != nil {
		f.Log.Errorf("Error parsing .netrc file: %v", err)
	}
	sources := map[string]*source{}
	for name, spec := range doc.Sources {
		if spec.URL == "" {
			return nil, fmt.Errorf("source '%s' has no 'url' defined in %s", name, path)
		}
		u, err := url.Parse(strings.TrimRight(spec.URL, "/"))
		if err != nil {
			return nil, fmt.Errorf("source '%s' has an invalid url: %w", name, err)
		}
		s := &source{name: name, url: u.String()}
		if c, ok := creds[u.Hostname()]; ok {
			s.username, s.password = c[0], c[1]
		}
		mode := "anonymous"
		if s.username != "" {
			mode = "authenticated"
		}
		f.Log.Debugf("Loaded source '%s' -> %s (%s)", name, s.url, mode)
		sources[name] = s
	}
	f.sourcesPath = path
	return sources, nil
}

func (f *Fetcher) netrcPath() string {
	if f.NetrcPath != "" {
		return f.NetrcPath
	}
	if p := os.Getenv("NETRC"); p != "" {
		return p
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	p := filepath.Join(home, ".netrc")
	if runtime.GOOS == "windows" {
		if _, err := os.Stat(p); err != nil {
			return filepath.Join(home, "_netrc")
		}
	}
	return p
}

// readNetrc returns login and password per machine. The "default" entry is
// deliberately ignored so a catch-all credential never reaches another host.
func readNetrc(path string) (map[string][2]string, error) {
	creds := map[string][2]string{}
	if path == "" {
		return creds, nil
	}
	file, err := os.Open(path)
	if errors.Is(err, os.ErrNotExist) {
		return creds, nil
	} else if err != nil {
		return creds, err
	}
	defer file.Close()

	var tokens []string
	inMacro := false
	sc := bufio.NewScanner(file)
	lineNo := 0
lines:
	for sc.Scan() {
		line := sc.Text()
		lineNo++
		if inMacro {
			if strings.TrimSpace(line) == "" {
				inMacro = false
			}
			continue
		}
		fields, err := shellwords.Split(line, shellwords.Netrc)
		if err != nil {
			return creds, fmt.Errorf("line %d: %w", lineNo, err)
		}
		for i, tok := range fields {
			if tok == "macdef" {
				inMacro = true
				tokens = append(tokens, fields[:i]...)
				continue lines
			}
		}
		tokens = append(tokens, fields...)
	}
	if err := sc.Err(); err != nil {
		return creds, err
	}

	machine, login, password := "", "", ""
	flush := func() {
		if machine != "" {
			creds[machine] = [2]string{login, password}
		}
		machine, login, password = "", "", ""
	}
	for i := 0; i < len(tokens); i++ {
		next := func() string {
			if i+1 < len(tokens) {
				i++
				return tokens[i]
			}
			return ""
		}
		switch tokens[i] {
		case "machine":
			flush()
			machine = next()
		case "default":
			flush()
		case "login":
			login = next()
		case "password":
			password = next()
		case "account":
			next()
		}
	}
	flush()
	return creds, nil
}
