package internal

// loader type: as a enum

type LoaderType uint16

const (
	MYSQL = LoaderType(1)
)

func (lt *LoaderType) String() string {
	switch *lt {
	case MYSQL:
		return "mysql"
	}
	return ""
}

func (lt *LoaderType) Unmarshal(value string) error {
	switch value {
	case "mysql":
		*lt = MYSQL
	}
	return nil

}
