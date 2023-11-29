## ONCHFS

The Onchain File System (ONCHFS) provides a way to store and retrieve files on
blockchain systems. It aims to provide a robust and efficient way to handle files within a blockchain environment, leveraging the power of content-addressable storage. The system works with 2 modules:

### Overview

Content-Addressable Store: This is a module responsible for storing chunks of data. Each chunk is indexed by the checksum of its data, ensuring that the data can be retrieved efficiently and accurately. This concept allows for the storage of data in a way that is independent of its location, with the data's address being derived from the data itself.
Index Nodes (INodes): INodes provide an index of files & directories that reference the Content-Addressable Store. They allow for the creation of directory structures and easy file retrieval. INodes, similar to their counterparts in UNIX-like systems, serve as tables referencing file/directory objects stored in the system along with related data.
HTTP Proxy Resolver: This component resolves the file objects and serves the content through the HTTP protocol. It's response for resolving ONCHFS URIs and fetching the corresponding content stored in the Content Store

### Creating Content

Creating content involves populating the content-addressable store with data. For large files, data can be split into multiple chunks (up to 24kb each). Once the data is stored, a reference to all the checksums that make up the file or directory is created in the INode store.

### Reading Content

Reading content involves retrieving the INode objects from the file store and then reading it inline. The system ensures that the content is delivered efficiently and accurately, thanks to the content-addressable storage and indexing.

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
