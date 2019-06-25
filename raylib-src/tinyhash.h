typedef struct hash_table_entry_t
{
  unsigned long hash;
  int filled;
  int pad0;
  long value;

  struct hash_table_entry_t* next;
} hash_table_entry_t;

typedef struct
{
  unsigned long* hashes;
  hash_table_entry_t* entries;
  unsigned int capacity;
  unsigned int n;
} hash_table_t;


unsigned long hash_djb2(const unsigned char* str);
void create_hash_table(unsigned int start_capacity, hash_table_t* hash_table);
void destroy_hash_table(hash_table_t* hash_table);
int hash_table_insert_value(unsigned long hash, long value, hash_table_t* hash_table);
int hash_table_insert(unsigned long hash, long value, hash_table_t* hash_table);
hash_table_entry_t* hash_table_find(unsigned long hash, hash_table_t* hash_table);
void hash_table_maybe_grow(unsigned int new_n, hash_table_t* hash_table);
int hash_table_exists(const char* name, hash_table_t* hash_table);
void hash_table_set(const char* name, unsigned int val, hash_table_t* hash_table);
long hash_table_get(const char* name, hash_table_t* hash_table);
