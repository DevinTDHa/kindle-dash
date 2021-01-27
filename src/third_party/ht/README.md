# ht
[![Version info](https://img.shields.io/crates/v/ht.svg)](https://crates.io/crates/ht)

Yet another [HTTPie](https://httpie.io/) clone in Rust.

[![asciicast](/assets/ht-demo.gif)](https://asciinema.org/a/382056)

## Installation
```sh
cargo install ht
```

**NB**: Make sure that you have Rust 1.46 or later installed.

## Usage
```
ht 0.3.2
USAGE:
    ht [FLAGS] [OPTIONS] <[METHOD] URL> [REQUEST_ITEM]...

FLAGS:
        --offline         Construct HTTP requests without sending them anywhere
    -j, --json            (default) Data items from the command line are serialized as a JSON object
    -f, --form            Data items from the command line are serialized as form fields
    -m, --multipart       Similar to --form, but always sends a multipart/form-data request (i.e., even without files)
    -I, --ignore-stdin    Do not attempt to read stdin
    -d, --download
    -c, --continue        Resume an interrupted download
    -v, --verbose         Print the whole request as well as the response
    -q, --quiet           Do not print to stdout or stderr
    -h, --help            Prints help information
    -V, --version         Prints version information

OPTIONS:
    -A, --auth-type <auth-type>              Specify the auth mechanism [possible values: Basic, Bearer]
    -a, --auth <auth>
    -o, --output <output>                    Save output to FILE instead of stdout
    -p, --print <print>                      String specifying what the output should contain
        --pretty <pretty>                    Controls output processing [possible values: All, Colors, Format, None]
    -s, --style <theme>                      Output coloring style [possible values: Auto, Solarized]
        --default-scheme <default-scheme>    The default scheme to use if not specified in the URL

ARGS:
    <[METHOD] URL>       The request URL, preceded by an optional HTTP method
    <REQUEST_ITEM>...    Optional key-value pairs to be included in the request
```

## Examples

```sh
# Send a GET request
ht httpbin.org/json

# Send a POST request with body {"name": "ahmed", "age": 24}
ht httpbin.org/post name=ahmed age:=24

# Send a GET request with querystring id=5&sort=true
ht get httpbin.org/json id==5 sort==true

# Send a GET request and include a header named x-api-key with value 12345
ht get httpbin.org/json x-api-key:12345

# Send a PUT request and pipe the result to less
ht put httpbin.org/put id:=49 age:=25 | less

# Download and save to res.json
ht -d httpbin.org/json -o res.json
```

## Syntaxes and themes used
- [Sublime-HTTP](https://github.com/samsalisbury/Sublime-HTTP)
- [json-kv](https://github.com/aurule/json-kv)
- [Sublime Packages](https://github.com/sublimehq/Packages/tree/fa6b8629c95041bf262d4c1dab95c456a0530122)
- [ansi-dark theme](https://github.com/sharkdp/bat/blob/master/assets/themes/ansi-dark.tmTheme)
