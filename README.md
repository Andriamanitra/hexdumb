# Hexdumb

like hexdump but more dumb and colorful

![screenshot](https://github.com/Andriamanitra/hexdumb/assets/10672443/a9af0d6e-6bd0-4d5e-8e12-aabc5dfb2b7d)




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
