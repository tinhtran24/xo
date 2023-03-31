package xo_wire

import (
	"github.com/google/wire"
)

var RepositorySet = wire.NewSet(
    {{ range . }}
        repo.New{{ camelCase .Table.TableName }}Repository,
    {{- end }}
)