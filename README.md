## ONCHFS

The Onchain File System (ONCHFS) provides a way to store and retrieve files on
blockchain systems. The system works with 2 modules:
- Content-Addressable Store: chunks of data indexed by checksum of their data
- Index Nodes (inodes): an index of Files & directories referencing the 
Content-Addressable Store, providing directory structures & easy file retrieval.

### File Objects

- In the spirit of inodes on UNIX-like systems, where inodes are tables referencing file/directory objects stored in cold memory and some data related 
to such objects, this provides an index of the files & directories stored in the file system
- A general table (map) maps a content key with its content (let it be a file or a directory)
- A file is a list of Content-Addressable pointers and some metadata attached to the file (such metadata being relevant for delivering the content through the http1 protocol)
- A directory is a map of (name -> inode pointer), referencing either a file or another directory under a name identifier

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploy

```shell
$ forge script script/Deploy.s.sol --rpc-url <rpc_url> --private-key <private_key>
```
