## Basic
http://blog.wafrat.com/test-coverage-in-dart-and-flutter/

`dart --pause-isolates-on-exit --disable-service-auth-codes --enable-vm-service=NNNN .\test\.test_coverage.dart`

## inspiration

https://github.com/cachapa/crdt
http://archagon.net/blog/2018/03/24/data-laced-with-history/
https://www.dotconferences.com/2019/12/james-long-crdts-for-mortals
https://cse.buffalo.edu/tech-reports/2014-04.pdf

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


# CRDTs
https://www.youtube.com/watch?v=B5NULPSiOGw&feature=emb_title
video: 31:56 Convergence definition

https://doi.org/10.1145/3133933
