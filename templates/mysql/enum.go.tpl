{{- $name := joinWith "_" .TableName .ColumnName -}}
{{ $camelName := camelCase $name }}
{{- $shortName := shortName $camelName -}}
package enum

type {{ $camelName }} uint16

const (
{{ range .Values }}
    {{ $camelName -}}{{- camelCase . }} {{ $camelName }} = iota 
{{ end }}
)

func ({{ $shortName }} {{ $camelName }}) String() string {
    var value string

    switch {{ $shortName }} {
        {{ range .Values }}
        case {{ $camelName -}}{{- camelCase . }}:
            value = "{{.}}" 
        {{ end }}
    }

    return value
}

func ({{ $shortName }} {{ $camelName }}) GoString() string {
    return {{ $shortName }}.String()
}


// UnmarshalText unmarshals {{ $camelName }} from text.
func ({{ $shortName }} *{{ $camelName }}) UnmarshalText(text []byte) error {
	switch string(text)	{

{{- range .Values }}
	case "{{.}}":
		*{{ $shortName }} = {{ $camelName -}}{{- camelCase . }}
{{ end }}

	default:
		return errors.New("ErrInvalidEnumGraphQL_{{ $camelName }}")
	}

	return nil
}

// Value satisfies the sql/driver.Valuer interface for {{ $camelName }}.
func ({{ $shortName }} {{ $camelName }}) Value() (driver.Value, error) {
	return {{ $shortName }}.String(), nil
}

// Value satisfies the sql/driver.Valuer interface for {{ $camelName }}.
func ({{ $shortName }} {{ $camelName }}) Ptr() *{{ $camelName }} {
	return &{{ $shortName }}
}

// Scan satisfies the database/sql.Scanner interface for {{ $camelName }}.
func ({{ $shortName }} *{{ $camelName }}) Scan(src interface{}) error {
	buf, ok := src.([]byte)
	if !ok {
	   return errors.New("ErrInvalidEnumScan_{{ $camelName }}")
	}

	return {{ $shortName }}.UnmarshalText(buf)
}
