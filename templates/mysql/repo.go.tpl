{{- $tableNameCamel := camelCase .Table.TableName -}}
{{- $shortName := shortName $tableNameCamel -}}

{{- $idType := "int" }}
{{- range .Table.Columns }}
    {{- if eq .ColumnName "id" }}
        {{- $idType = .GoType }}
    {{- end}}
{{- end }}

package repo

import (
    sq "github.com/elgris/sqrl"
    "github.com/google/wire"
)

type I{{ $tableNameCamel }}Repository interface {
    I{{ $tableNameCamel }}RepositoryQueryBuilder
    
    Insert{{ $tableNameCamel }}(ctx context.Context, {{ $shortName }} table.{{ $tableNameCamel }}Create) (*table.{{ $tableNameCamel }}, error)
    Insert{{ $tableNameCamel }}WithSuffix(ctx context.Context, {{ $shortName }} table.{{ $tableNameCamel }}Create, suffix sq.Sqlizer) (*table.{{ $tableNameCamel }}, error)
    Insert{{ $tableNameCamel }}IDResult(ctx context.Context, {{ $shortName }} table.{{ $tableNameCamel }}Create, suffix sq.Sqlizer) (int64, error)

    Update{{ $tableNameCamel }}ByFields(ctx context.Context, id {{ $idType }}, {{ $shortName }} table.{{ $tableNameCamel }}Update) (*table.{{ $tableNameCamel }}, error)
    Update{{ $tableNameCamel }}(ctx context.Context, {{ $shortName }} table.{{ $tableNameCamel }}) (*table.{{ $tableNameCamel }}, error)
    
    Delete{{ $tableNameCamel }}(ctx context.Context, {{ $shortName }} table.{{ $tableNameCamel }}) error
    Delete{{ $tableNameCamel }}ByID(ctx context.Context, id {{ $idType }}) (bool, error)
    
    FindAll{{ $tableNameCamel }}(ctx context.Context, {{ $shortName }} *table.{{ $tableNameCamel }}Filter, pagination *internal.Pagination) (table.List{{ $tableNameCamel }}, error)
    FindAll{{ $tableNameCamel }}WithSuffix(ctx context.Context,{{ $shortName }} *table.{{ $tableNameCamel }}Filter, pagination *internal.Pagination, suffixes ...sq.Sqlizer) (table.List{{ $tableNameCamel }}, error)

}


type I{{ $tableNameCamel }}RepositoryQueryBuilder interface {
    FindAll{{ $tableNameCamel }}BaseQuery(ctx context.Context, filter *table.{{ $tableNameCamel }}Filter, fields string, suffix ...sq.Sqlizer) (*sq.SelectBuilder, error)
    AddPagination(ctx context.Context, qb *sq.SelectBuilder, pagination *internal.Pagination) (*sq.SelectBuilder, error)
}

type {{ $tableNameCamel }}Repository struct {
    DB internal.IDb
    QueryBuilder I{{ $tableNameCamel }}RepositoryQueryBuilder
}

type {{ $tableNameCamel }}RepositoryQueryBuilder struct {
}

var New{{ $tableNameCamel }}Repository = wire.NewSet(
    wire.Struct(new({{ $tableNameCamel }}Repository), "*"),
    wire.Struct(new({{ $tableNameCamel }}RepositoryQueryBuilder), "*"),
    wire.Bind(new(I{{ $tableNameCamel }}Repository), new({{ $tableNameCamel }}Repository)),
    wire.Bind(new(I{{ $tableNameCamel }}RepositoryQueryBuilder), new({{ $tableNameCamel }}RepositoryQueryBuilder)),
)

func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) Insert{{ $tableNameCamel }}(ctx context.Context, {{ $shortName }} table.{{ $tableNameCamel }}Create) (*table.{{ $tableNameCamel }}, error) {
    return {{ $shortName }}r.Insert{{ $tableNameCamel }}WithSuffix(ctx, {{ $shortName }}, nil)
}

func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) Insert{{ $tableNameCamel }}WithSuffix(ctx context.Context, {{ $shortName }} table.{{ $tableNameCamel }}Create, suffix sq.Sqlizer) (*table.{{ $tableNameCamel }}, error) {
    var err error
    
    id, err := {{ $shortName }}r.Insert{{ $tableNameCamel }}IDResult(ctx, {{ $shortName }}, suffix)
    if err != nil {
        return nil, err
    }
    new{{ $shortName }} := table.{{ $tableNameCamel }}{}
    qb := sq.Select("*").From(`{{ .Table.TableName }}`)

    qb.Where(sq.Eq{"`id`": id})
    err = {{ $shortName }}r.DB.Get(ctx, &new{{ $shortName }}, qb)

    if err != nil {
        return nil, err
    }
    return &new{{ $shortName }}, nil
}

func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) Insert{{ $tableNameCamel }}IDResult(ctx context.Context, {{ $shortName }} table.{{ $tableNameCamel }}Create, suffix sq.Sqlizer) (int64, error) {
    var err error

    qb := sq.Insert("`{{ .Table.TableName }}`").Columns(
        {{- range .Table.Columns }}
            "`{{ .ColumnName }}`",
        {{- end }}
    ).Values(
        {{- range .Table.Columns }}
            {{ $shortName }}.{{ camelCase .ColumnName }},
        {{- end }}
    )
    if suffix != nil {
        suffixQuery, suffixArgs, suffixErr := suffix.ToSql()
        if suffixErr != nil {
            return 0, suffixErr
        }
        qb.Suffix(suffixQuery, suffixArgs...)
    }

    // run query
	res, err := {{ $shortName }}r.DB.Exec(ctx, qb)
	if err != nil {
		return 0, err
	}

    // retrieve id
	id, err := res.LastInsertId()
	if err != nil {
		return 0, err
	}

    return id, nil
} 

func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) Update{{ $tableNameCamel }}ByFields(ctx context.Context, id {{ $idType }}, {{ $shortName }} table.{{ $tableNameCamel }}Update) (*table.{{ $tableNameCamel }}, error) {
    var err error 

    updateMap := map[string]interface{}{}
    {{- range .Table.Columns }}
        if ({{ $shortName }}.{{ camelCase .ColumnName }} != nil) {
            updateMap["`{{ .ColumnName }}`"] = *{{ $shortName }}.{{ camelCase .ColumnName }}
        }
    {{- end }}

    qb := sq.Update(`{{ .Table.TableName }}`).SetMap(updateMap).Where(sq.Eq{"`id`": id})

    _, err = {{ $shortName }}r.DB.Exec(ctx, qb)
    if err != nil {
        return nil, err
    }

    selectQb := sq.Select("*").From("`{{ $.Table.TableName }}`")

    selectQb = selectQb.Where(sq.Eq{"`id`": id})

    result := table.{{ $tableNameCamel }}{}
    err = {{ $shortName }}r.DB.Get(ctx, &result, selectQb)
    if err != nil {
        return nil, err
    }

    return &result, nil

}


func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) Update{{ $tableNameCamel }}(ctx context.Context, {{ $shortName }} table.{{ $tableNameCamel }}) (*table.{{ $tableNameCamel }}, error) {
    var err error

    // sql query
    qb := sq.Update("`{{ .Table.TableName }}`").SetMap(map[string]interface{}{
    {{- range .Table.Columns }}
        {{- if ne .ColumnName "id" }}
        "`{{ .ColumnName }}`": {{ $shortName }}.{{ camelCase .ColumnName }},
        {{- end }}
    {{- end }}
    }).Where(sq.Eq{"`id`": {{ $shortName }}.ID})

    // run query
    _, err = {{ $shortName }}r.DB.Exec(ctx, qb)
    if err != nil {
        return nil, err
    }

    selectQb := sq.Select("*").From("`{{ .Table.TableName }}`")
    selectQb = selectQb.Where(sq.Eq{"`id`": {{ $shortName }}.ID})
    
    result := table.{{ $tableNameCamel }}{}
    err = {{ $shortName }}r.DB.Get(ctx, &result, selectQb)
    if err != nil {
        return nil, err
    }

    return &result, nil
}


func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) Delete{{ $tableNameCamel }}(ctx context.Context, {{ $shortName }} table.{{ $tableNameCamel }}) (error) {
    _, err := {{ $shortName }}r.Delete{{ $tableNameCamel }}ByID(ctx, {{ $shortName }}.ID)
    return err
}


func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) Delete{{ $tableNameCamel }}ByID(ctx context.Context, id {{ $idType }}) (bool, error) {
    var err error

    qb := sq.Update("`{{ .Table.TableName }}`").Set("active", false)

    qb = qb.Where(sq.Eq{"`id`": id})

    _, err = {{ $shortName }}r.DB.Exec(ctx, qb)
    if err != nil {
        return false, err
    } 
    return true, nil
}

func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) FindAll{{ $tableNameCamel }}BaseQuery(ctx context.Context, filter *table.{{ $tableNameCamel }}Filter, fields string, suffixes ...sq.Sqlizer) (*sq.SelectBuilder, error) {
    return {{ $shortName }}r.QueryBuilder.FindAll{{ $tableNameCamel }}BaseQuery(ctx, filter, fields, suffixes...)
}

func ({{ $shortName }}r *{{ $tableNameCamel }}RepositoryQueryBuilder) FindAll{{ $tableNameCamel }}BaseQuery(ctx context.Context, filter *table.{{ $tableNameCamel }}Filter, fields string, suffixes ...sq.Sqlizer) (*sq.SelectBuilder, error) {
    var err error
    qb := sq.Select(fields).From("`{{ .Table.TableName }}`")
    if filter != nil {
        {{- range .Table.Columns }}
            {{- if eq .ColumnName "active" }}
                if filter.Active == nil {
                    if qb, err = internal.AddFilter(qb, "`{{ $.Table.TableName }}`.`active`", internal.FilterOnField{ {internal.Eq: true} }); err != nil {
                        return qb, err
                    }
                } else {
                    if qb, err = internal.AddFilter(qb, "`{{ $.Table.TableName }}`.`active`", filter.Active); err != nil {
                        return qb, err
                    }
                }
            {{- else }}
                if qb, err = internal.AddFilter(qb, "`{{ $.Table.TableName }}`.`{{ .ColumnName }}`", filter.{{ camelCase .ColumnName }}); err != nil {
                    return qb, err
                }
            {{- end }}
        {{- end }}
        qb, err = internal.AddAdditionalFilter(qb, filter.Wheres, filter.Joins, filter.LeftJoins, filter.GroupBys, filter.Havings)
        if err != nil {
            return qb, err
        }
    }
    {{- range .Table.Columns }}
        {{- if eq .ColumnName "active" }} else {
            if qb, err = internal.AddFilter(qb, "`{{ $.Table.TableName }}`.`active`", internal.FilterOnField{ {internal.Eq: true} }); err != nil {
                return qb, err
            }
        }
        {{- end }}
    {{- end }}

    for _, suffix := range suffixes {
        query, args, err := suffix.ToSql()
        if err != nil {
            return qb, err
        }
        qb.Suffix(query, args...)
    }
    return qb, nil
}

func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) AddPagination(ctx context.Context, qb *sq.SelectBuilder, pagination *internal.Pagination) (*sq.SelectBuilder, error) {
    return {{ $shortName }}r.QueryBuilder.AddPagination(ctx, qb, pagination)
}

func ({{ $shortName }} *{{ $tableNameCamel }}RepositoryQueryBuilder) AddPagination(ctx context.Context, qb *sq.SelectBuilder, pagination *internal.Pagination) (*sq.SelectBuilder, error) {
    fields := []string {
        {{- range .Table.Columns }}   
            "{{ .ColumnName }}",
        {{- end }}
    }
    return internal.AddPagination(qb, pagination, "{{ .Table.TableName }}", fields)
}

func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) FindAll{{ $tableNameCamel }}(ctx context.Context, filter *table.{{ $tableNameCamel }}Filter, pagination *internal.Pagination) (list table.List{{ $tableNameCamel }}, err error) {
    return {{ $shortName }}r.FindAll{{ $tableNameCamel }}WithSuffix(ctx, filter, pagination)
}

func ({{ $shortName }}r *{{ $tableNameCamel }}Repository) FindAll{{ $tableNameCamel }}WithSuffix(ctx context.Context, filter *table.{{ $tableNameCamel }}Filter, pagination *internal.Pagination, suffixes ...sq.Sqlizer) (list table.List{{ $tableNameCamel }}, err error) {
    qb, err := {{ $shortName }}r.FindAll{{ $tableNameCamel }}BaseQuery(ctx, filter, "`{{ .Table.TableName }}`.*", suffixes...)
    if err != nil {
        return table.List{{ $tableNameCamel }}{}, err
    }
    qb, err = {{ $shortName }}r.AddPagination(ctx, qb, pagination)
    if err != nil {
        return table.List{{ $tableNameCamel }}{}, err
    }

    err = {{ $shortName }}r.DB.Select(ctx, &list.Data, qb)

    if err != nil {
        return list, err
    }

    if pagination == nil || pagination.PerPage == nil || pagination.Page == nil {
        list.TotalCount = len(list.Data)
        return list, nil
    }

    var listMeta internal.ListMetadata
    if qb, err = {{ $shortName }}r.FindAll{{ $tableNameCamel }}BaseQuery(ctx, filter, "COUNT(1) AS count"); err != nil {
        return table.List{{ $tableNameCamel }}{}, err
    }
    if filter != nil && len(filter.GroupBys) > 0 {
        qb = sq.Select("COUNT(1) AS count").FromSelect(qb, "a")
    }
    err = {{ $shortName }}r.DB.Get(ctx, &listMeta, qb)

    list.TotalCount = listMeta.Count

    return list, err
}
