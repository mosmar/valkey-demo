# CRUD Operations in Valkey

Valkey is a high-performance key-value store (a fork of Redis). CRUD operations map to the ways you manage data across its data structures.

---

## **C – Create**
Adding new key-value pairs.

- `SET key value` → Store a string value under a key  
- `HSET hash field value` → Create a hash field  
- `LPUSH list value` → Add to the beginning of a list  
- `SADD set value` → Add a member to a set  

---

## **R – Read**
Retrieving data from Valkey.

- `GET key` → Get the string value of a key  
- `HGET hash field` → Get a value from a hash  
- `LRANGE list start stop` → Read list items  
- `SMEMBERS set` → Get all members of a set  

---

## **U – Update**
Modifying existing data (usually by overwriting or updating fields).

- `SET key newValue` → Overwrite the string value  
- `HSET hash field newValue` → Update a field in a hash  
- `LSET list index newValue` → Update an item at a specific index  
- `SADD set newValue` → Add new elements if not already present  

---

## **D – Delete**
Removing data.

- `DEL key` → Delete a key (works on any type)  
- `HDEL hash field` → Remove a field from a hash  
- `LREM list count value` → Remove matching items from a list  
- `SREM set value` → Remove a member from a set  

---

## ⚡ Key Difference from SQL Databases
Valkey doesn’t have *tables* or *rows*.  
CRUD is applied across **different data structures** (strings, hashes, lists, sets, sorted sets, streams, etc.).
