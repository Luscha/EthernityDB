# EternityDB
A NoSQL Document based DB implementation on top of the Ethereum Project blockchain.

The driver will use a subset of the BSON binary seralization to store and handle NoSQL documents in Json format.

For the sake of simplicity
--------------------------
The NoSQL implementation accepts only documents with at most 8 level of embedded documents.
The key must also be at most 30 character long.
The maximum length of a document is the unsigned 32 bit integer value - 21 (4.294.967.274) bytes.


Reduced BSON grammar:
-------------
<pre><code>
document	::=	int32 e_list "\x00"	BSON Document. int32 is the total number of bytes comprising the document.
e_list	::=	element e_list
  |	""
element	::=	"\x02" e_name string	         UTF-8 string
  |	"\x03" e_name document	       Embedded document
  |	"\x04" e_name document	       Array
  |	"\x07" e_name (byte*12)	       ObjectId
  |	"\x08" e_name "\x00"	         Boolean "false"
  |	"\x08" e_name "\x01"	         Boolean "true"
  |	"\x0A" e_name	                 Null value
  |	"\x10" e_name int32	           32-bit integer
  |	"\x11" e_name uint64	         Timestamp
  |	"\x12" e_name int64	           64-bit integer
e_name	::=	cstring	                 Key name
string	::=	int32 (byte*) "\x00"	   String - The int32 is the number bytes in the (byte*) + 1 (for the trailing '\x00'). The (byte*) is zero or more UTF-8 encoded characters.
cstring	::=	(byte*) "\x00"	         Zero or more modified UTF-8 encoded characters followed by '\x00'. The (byte*) MUST NOT contain '\x00', hence it is not full UTF-8.
</code></pre>

The driver will also use some reserved single-byte keys to identify logical operation over the SELECT closure.

The AND operation is identified simply with a " , " that separates the keys of the closure.
In an OR operation the comma separates the single condition of the statement (one of them has to be true to satisfy the operation)

| Key (HEX) | Operation | Required value format | Example |
| --------- | --------- | --------------------- | ------- |
| 0x2C | AND | Conditions separated by commas | key1: value1, key2: value2 |
| 0x7c | OR | Array of conditions | '0x7c': [{key1: value1}, {key2: value2}] |
| 0x20 | > | Value of the comparison | key: {'0x20': value} |
| 0x21 | >= | Value of the comparison | key: {'0x21': value} |
| 0x22 | < | Value of the comparison | key: {'0x22': value} |
| 0x23 | <= | Value of the comparison | key: {'0x23': value} |
| 0x24 | != | Value of the comparison | key: {'0x24': value} |
| 0x25 | == | Value of the comparison | key: {'0x25': value} or simply key: value |
