
db.setProfilingLevel(2)

db.system.profile.find().limit(2).sort( { ts : -1 } ).pretty()
db.book.getIndexes()


1  - db.book.createIndex({"_id" : 1})

2 -  db.book.createIndex({"name" : 1, "_id" : 1})

3 - db.book.createIndex( { _id: "hashed" } )

db.setProfilingLevel(0)


db.book.dropIndex("_id")