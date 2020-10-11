# Jadx

## 源码编译

Java 8 JDK 或者更高版本

```
git clone https://github.com/skylot/jadx.git
cd jadx
./gradlew dist
```

(on Windows, use `gradlew.bat` instead of `./gradlew`)

## 运行

```
cd build/jadx/
bin/jadx -d out lib/jadx-core-*.jar
# or
bin/jadx-gui lib/jadx-core-*.jar
```

## 使用说明

```
jadx[-gui] [options] <input file> (.dex, .apk, .jar or .class)
options:
 -d,  --output-dir           - output directory
 -ds, --output-dir-src       - output directory for sources
 -dr, --output-dir-res       - output directory for resources
 -j,  --threads-count        - processing threads count
 -r,  --no-res               - do not decode resources
 -s,  --no-src               - do not decompile source code
 -e,  --export-gradle        - save as android gradle project
      --show-bad-code        - show inconsistent code (incorrectly decompiled)
      --no-imports           - disable use of imports, always write entire package name
      --no-replace-consts    - don't replace constant value with matching constant field
      --escape-unicode       - escape non latin characters in strings (with \u)
      --deobf                - activate deobfuscation
      --deobf-min            - min length of name
      --deobf-max            - max length of name
      --deobf-rewrite-cfg    - force to save deobfuscation map
      --deobf-use-sourcename - use source file name as class name alias
      --cfg                  - save methods control flow graph to dot file
      --raw-cfg              - save methods control flow graph (use raw instructions)
 -f,  --fallback             - make simple dump (using goto instead of 'if', 'for', etc)
 -v,  --verbose              - verbose output
 -h,  --help                 - print this help
Example:
 jadx -d out classes.dex

```

## Out of memory

- Reduce processing threads count (-j option)

- Increase maximum java heap size:

    - command line (example for linux): JAVA_OPTS="-Xmx4G" jadx -j 1 some.apk
    - edit 'jadx' script (jadx.bat on Windows) and setup bigger heap size: DEFAULT_JVM_OPTS="-Xmx2500M"
