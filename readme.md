http://archagon.net/blog/2018/03/24/data-laced-with-history/

## Specs

#### Message format:

Simple format

ts: HLC timetamp
id: Client id/Site Id/ Node Id

Table: Table(Rational Db)/ Collection Id ( NoSql)
Row: Row Id / Object ID
field: Column (RDb) / Field of Document (NoSql)
value: encoded value in bytes

```
     | ts : id : table : row : field : value
Bytes|  8 :  4 :     4 :   16 :     4 : any
```
