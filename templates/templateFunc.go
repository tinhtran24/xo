package templates

import (
	"html/template"
	"regexp"
	"strings"

	"github.com/kenshaw/snaker"
)

var removeSpecialChar = regexp.MustCompile(`[^a-zA-Z0-9]`)

var HelperFunc template.FuncMap = template.FuncMap{
	"camelCase": func(input string) string {
		return snaker.SnakeToCamel(removeSpecialChar.ReplaceAllLiteralString(input, "_"))
	},
	"joinWith":  joinWith,
	"shortName": shortName,
}

func joinWith(with string, values ...string) string {
	return strings.Join(values, with)
}

// fetch only uppercase values
func shortName(name string) string {
	short := strings.ToLower(strings.Map(func(r rune) rune {
		if r >= 'A' && r <= 'Z' {
			return r
		}
		return -1
	}, name))

	if len(short) == 0 {
		short = strings.ToLower(name[0:1])
	}
	if short == "er" || short == "err" || short == "va" || short == "var" {
		short = short + "_"
	}
	return short
}
