{{- $tableNameCamel := camelCase .TableName -}}
package table

import (
    sq "github.com/elgris/sqrl"
    "github.com/pkg/errors"
)

type {{ $tableNameCamel }} struct {
{{- range .Columns}}
{{- if and .IsEnum (eq .NotNullable false) }}
    {{ camelCase .ColumnName }} *{{ .GoType }} `json:"{{.ColumnName}}" db:"{{.ColumnName}}"`
{{ else }}
    {{ camelCase .ColumnName }} {{ .GoType }} `json:"{{.ColumnName}}" db:"{{.ColumnName}}"`
{{- end }}
{{- end }}
}

type {{ $tableNameCamel }}Filter struct {
{{- range .Columns}}
    {{ camelCase .ColumnName }} internal.FilterOnField 
{{- end }}
    Wheres []sq.Sqlizer
    Joins []sq.Sqlizer
    LeftJoins []sq.Sqlizer
    GroupBys []string
    Havings []sq.Sqlizer
}

func (f *{{ $tableNameCamel }}Filter) NewFilter() interface{} {
    if f == nil {
        return &{{ $tableNameCamel }}Filter{}
    }
    return f
}

func (f *{{ $tableNameCamel }}Filter) TableName() string {
    return "`{{ .TableName }}`"
}

func (f *{{ $tableNameCamel }}Filter) ModuleName() string {
    return "{{ .TableName }}"
}

func (f *{{ $tableNameCamel }}Filter) IsNil() bool {
    return f == nil
}

{{- range .Columns}}
func (f *{{ $tableNameCamel }}Filter) Add{{ camelCase .ColumnName }}(filterType internal.FilterType, v interface{}) {
    f.{{camelCase .ColumnName }} = append(f.{{camelCase .ColumnName }}, map[internal.FilterType]interface{}{filterType: v})
}
{{- end }}

func (f *{{ $tableNameCamel }}Filter) Where(v sq.Sqlizer) *{{ $tableNameCamel }}Filter {
    f.Wheres = append(f.Wheres, v)
    return f
}


func (f *{{ $tableNameCamel }}Filter) Join(j sq.Sqlizer) *{{ $tableNameCamel }}Filter {
    f.Joins = append(f.Joins, j)
    return f
}

func (f *{{ $tableNameCamel }}Filter) LeftJoin(j sq.Sqlizer) *{{ $tableNameCamel }}Filter {
    f.LeftJoins = append(f.LeftJoins, j)
    return f
}

func (f *{{ $tableNameCamel }}Filter) GroupBy(gb string) *{{ $tableNameCamel }}Filter {
    f.GroupBys = append(f.GroupBys, gb)
    return f
}

func (f *{{ $tableNameCamel }}Filter) Having(h sq.Sqlizer) *{{ $tableNameCamel }}Filter {
    f.Havings = append(f.Havings, h)
    return f
}

// Hashing is used for caching... we don't need it here.


// TODO: CreateEntity is for graphql I think 🤔
type {{ $tableNameCamel }}Create struct {
{{- range .Columns}}
    {{ camelCase .ColumnName }} {{ .GoType }} `json:"{{.ColumnName}}" db:"{{.ColumnName}}"`
{{- end }}
}

// TODO: We have to exclude AutoGenerated fields
// For now I am keeping it in, as not sure how it affects
type {{ $tableNameCamel }}Update struct {
{{- range .Columns}}
    {{ camelCase .ColumnName }} *{{ .GoType }} // {{.ColumnName}}
{{- end }}
}


// helper functions
func (u *{{ $tableNameCamel }}Update) To{{ $tableNameCamel }}Create() (res {{ $tableNameCamel }}Create, err error) {
{{- range .Columns}}
{{- if eq .IsGenerated false }}
    if u.{{ camelCase .ColumnName }} != nil {
        res.{{ camelCase .ColumnName }} = *u.{{ camelCase .ColumnName }}
    }
    {{- if eq .NotNullable true -}} 
    {{" "}}else {
        return res, errors.New("Value Can not be NULL")
    } 
    {{- end -}}
{{- end -}}
{{- end }}
    return res, nil
}

type List{{ $tableNameCamel }} struct {
    TotalCount int
    Data []{{ $tableNameCamel }}
}

{{- range .Columns }}
    {{- if and .IsEnum (eq .NotNullable false) }}
func (l *List{{ $tableNameCamel }}) GetAll{{ camelCase .ColumnName }}() []*{{ .GoType }} {
    var res []*{{ .GoType }}
    for _, item := range l.Data {
        res = append(res, item.{{ camelCase .ColumnName }})
    }
    return res
}
    {{- else }}
func (l *List{{ $tableNameCamel }}) GetAll{{ camelCase .ColumnName }}() []{{ .GoType }} {
    var res []{{ .GoType }}
    for _, item := range l.Data {
        res = append(res, item.{{ camelCase .ColumnName }})
    }
    return res
}
    {{- end }}
{{- end }}

func (l *List{{ $tableNameCamel }}) Filter(f func (item {{ $tableNameCamel }}) bool) (res List{{ $tableNameCamel }}) {
    for _, item := range l.Data {
        if f(item) {
            res.Data = append(res.Data, item)
        }
    }
    res.TotalCount = len(res.Data)
    return res
}

func (l *List{{ $tableNameCamel }}) Find(f func (item {{ $tableNameCamel }}) bool) (res {{ $tableNameCamel }}, found bool) {
    for _, item := range l.Data {
        if f(item) {
            return item, true
        }
    }
    return {{ $tableNameCamel }}{}, false
}



