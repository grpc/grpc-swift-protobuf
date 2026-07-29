# ``GoogleRPCStatus``

## Topics

### Creating a status

- ``GoogleRPCStatus/init(code:message:details:)-(RPCError.Code,String,[ErrorDetails])``
- ``GoogleRPCStatus/init(code:message:details:)-(RPCError.Code,String,ErrorDetails...)``

### Inspecting a status

- ``GoogleRPCStatus/code``
- ``GoogleRPCStatus/message``
- ``GoogleRPCStatus/details``

### Encoding and decoding a status

- ``GoogleRPCStatus/init(serializedBytes:extensions:partial:options:)``
- ``GoogleRPCStatus/serializedBytes(partial:options:)``

### Converting to an RPC error

- ``GoogleRPCStatus/rpcErrorCode``
- ``GoogleRPCStatus/rpcErrorMessage``
- ``GoogleRPCStatus/rpcErrorMetadata``

### Extracting a status from an RPC error

- ``GRPCCore/RPCError/unpackGoogleRPCStatus()``
