# Format of binary slaw files

Binary slaw files, as written by the `slaw_output_open_binary` family
of functions, and read by the `slaw_input_open_binary` family of
functions, always begin with an 8-byte header:

```
    0       1       2       3       4       5       6       7
+-------+-------+-------+-------+-------+-------+-------+-------+
|   FF  |   FF  |   0B  |   10  |  vers |  type |     flags     |
+-------+-------+-------+-------+-------+-------+-------+-------+
```

The header begins with a 4-byte magic number: `ff ff 0b 10`.

Next comes one byte of version, one byte of type, and two bytes of
flags.

The version is the slaw version of the slawx contained in this file.
Currently, we always write version 2, but can read either 1 or 2.  See
the files [slaw-v1.md](internal/slaw-v1.md) and
[slaw-v2.md](slaw-v2.md) for details of the two versions.

The type is `PLASMA_BINARY_FILE_TYPE_SLAW` (1) to indicate that this
is a slaw file.  The type `PLASMA_BINARY_FILE_TYPE_POOL` (2) also
exists, but is not documented by this specification.  Additional types
could be allocated in the future if we need to have binary files that
contain something other than slawx or proteins.

The flags are interpreted as a 16-bit big-endian number, and current
only one bit is used: `PLASMA_BINARY_FILE_FLAG_BIG_ENDIAN_SLAW` (the
least-significant bit of the 16-bit field).  Unrecognized flags are
ignored.

The header is followed by zero or more binary serialized slawx.  The
slawx are encoded using the slaw version and endianness specified in
the header.
