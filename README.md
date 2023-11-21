# Hexdumb

like hexdump but more dumb and colorful


## Usage

```sh
# you can give it a file to read
hexdumb README.md
# or just pipe stuff to it
echo "hexdumb is dumb" | hexdumb
```


## Installing

You need [Crystal-lang](https://crystal-lang.org/) to compile hexdumb.

```sh
# compile
crystal build --release --progress hexdumb.cr
# copy executable to home directory (Linux)
cp hexdumb ~/.local/bin/hexdumb
```
