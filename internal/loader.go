package internal

import (
	"fmt"
	"strings"

	"github.com/tinhtran24/xo/loaders/models"
	"github.com/tinhtran24/xo/templates"
)

// The loader interface
type ILoader interface {
	LoadSchema(*Args) error
}

var AllLoaders = map[LoaderType]ILoader{}

// The loader implementation
// Drivers like mysql will create object for this.
type LoaderImp struct {
	EnumList        func(db models.XODB, databaseName string) ([]*models.Enum, error)
	DatabaseName    func(db models.XODB) (string, error)
	EnumValueList   func(db models.XODB, databaseName string, tableName string, columnName string) (string, error)
	TableList       func(db models.XODB, databaseName string) ([]string, error)
	ColumList       func(db models.XODB, databaseName string, tableName string) ([]*models.Column, error)
	IndexList       func(db models.XODB, databaseName string, tableName string) ([]*models.Index, error)
	ForeignKeysList func(db models.XODB, databaseName string, tableName string) ([]*models.ForeignKey, error)
}

// Entry point to load everything
func (lt *LoaderImp) LoadSchema(args *Args) error {
	var err error

	database, err := lt.loadDatabaseName(args)
	if err != nil {
		return err
	}
	args.DatabaseName = database

	err = lt.loadEnums(args)
	if err != nil {
		return err
	}

	tables, err := lt.loadTables(args)
	if err != nil {
		return err
	}

	fmt.Println("Loading repo..")

	tableRelations, err := lt.loadRepository(args, tables)
	if err != nil {
		return err
	}
	err = args.ExecuteTemplate(templates.XO_WIRE, "wire.xo", tableRelations)
	if err != nil {
		return err
	}

	return nil
}

func (lt *LoaderImp) loadDatabaseName(args *Args) (string, error) {
	if lt.DatabaseName == nil {
		return "", fmt.Errorf("schema name loader is not implemented for %s", args.LoaderType.String())
	}
	return lt.DatabaseName(args.DB)
}

type TableRelation struct {
	Table       *TableDTO
	Indexes     []*models.Index
	ForeignKeys []*models.ForeignKey
}

func (lt *LoaderImp) loadRepository(args *Args, tables []*TableDTO) ([]*TableRelation, error) {

	res := []*TableRelation{}

	for _, table := range tables {
		indexes, err := lt.IndexList(args.DB, args.DatabaseName, table.TableName)
		if err != nil {
			return nil, err
		}
		foreignKeys, err := lt.ForeignKeysList(args.DB, args.DatabaseName, table.TableName)
		if err != nil {
			return nil, err
		}
		tableRelation := &TableRelation{
			Table:       table,
			Indexes:     indexes,
			ForeignKeys: foreignKeys,
		}
		err = args.ExecuteTemplate(templates.REPO, table.TableName+"_repository", tableRelation)
		if err != nil {
			return nil, err
		}
		res = append(res, tableRelation)
	}
	return res, nil
}

type TableDTO struct {
	TableName string
	Columns   []*models.Column
}

func (lt *LoaderImp) loadTables(args *Args) ([]*TableDTO, error) {
	tables, err := lt.TableList(args.DB, args.DatabaseName)
	if err != nil {
		return nil, err
	}
	var allTableDTO []*TableDTO

	for _, table := range tables {
		columns, err := lt.ColumList(args.DB, args.DatabaseName, table)
		if err != nil {
			return nil, err
		}
		allTableDTO = append(allTableDTO, &TableDTO{
			TableName: table,
			Columns:   columns,
		})
	}

	for _, table := range allTableDTO {
		err := args.ExecuteTemplate(templates.TABLE, table.TableName, table)
		if err != nil {
			return nil, err
		}
	}
	return allTableDTO, nil

}

type EnumDTO struct {
	*models.Enum
	DatabaseName string
	Values       []string
}

func (lt *LoaderImp) loadEnums(args *Args) error {
	enums, err := lt.EnumList(args.DB, args.DatabaseName)
	if err != nil {
		return err
	}

	var allEnumDTO []*EnumDTO
	for _, e := range enums {
		// fmt.Printf("%s, %s \n", e.ColumnName, e.TableName)
		enumValues, err := lt.loadEnumValues(args, e)

		if err != nil {
			return err
		}

		allEnumDTO = append(allEnumDTO, &EnumDTO{
			e,
			args.DatabaseName,
			enumValues,
		})
	}

	for _, enum := range allEnumDTO {
		err := args.ExecuteTemplate(templates.ENUM, fmt.Sprintf("%s_%s", enum.TableName, enum.ColumnName), enum)
		if err != nil {
			return err
		}
	}

	// fmt.Printf(""enums)
	return nil
}

func (lt *LoaderImp) loadEnumValues(args *Args, enum *models.Enum) ([]string, error) {
	if lt.EnumValueList == nil {
		return nil, fmt.Errorf("enumValue loader is not implemented for %s", args.LoaderType.String())
	}

	values, err := lt.EnumValueList(args.DB, args.DatabaseName, enum.TableName, enum.ColumnName)

	if err != nil {
		return nil, err
	}
	// value is in 'A','B','C' we want to convert to a list
	list := strings.Split(values[1:len(values)-1], "','")
	return list, nil
}
