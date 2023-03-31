# xo

- [When should I use a pointer to an interface?](https://www.reddit.com/r/golang/comments/kit3da/whats_the_meaning_of_a_pointer_to_an_interface/)

- [Prime Reacts: The Flaws of Inheritance](https://youtu.be/HOSdPhAKupw) <- How this can relate to MySQL loader and LoderImp architecture

i) args: a object we pass around and collect data.
ii) loaderImp: a single implementation of loader
  - for each sql driver we create different object.

- for loaderImp I would have preferred separate implementation for each driver  

dir/internal:
args: pass arguments each for whole process 
 args stores data like DTO for the process

loader: a generic loader object and single implementation

dir/loaders:
specific loaders like mysql

- Can not import main pack into another package
  -  have to create cmd package 
eg of fail case 
```go
package main

import (
	xo "github.com/tinhtran24/xo"
)

func main() {
	xo.Execute("")
}

```
https://stackoverflow.com/questions/44420826/access-main-package-from-other-package

- Tools 
For dev-dependency go recommend following ([Github Issue](https://github.com/golang/go/issues/25922#issuecomment-1038394599)).
More about it on ([keep](https://github.com/ketan-10/keep))
  - go-bindata: 
    - go-bindata generate golang file that stores the files in go-code i.e. in-memory.
    - This makes file access fast and using it we can have single binary build easily.
    - here I have used this due to we are running this from other location and file path mess up. and gives error template file not exist.
