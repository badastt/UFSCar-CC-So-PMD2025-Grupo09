CALL apoc.mongo.aggregate(
  "mongodb://localhost:27017/arXiv.papers",
  apoc.convert.fromJsonList('[
  {
    "$unwind": "$bib"
  },
  {
    "$addFields": {
      "match_arxiv_id": {
        "$regexFindAll": {
          "input": "$bbl",
          "regex": "arXiv:\\\\d+\\\\.\\\\d+(v\\\\d+)?",
                            "options": "i"
        }
      }
    }
  },
  {
    "$project": {
      "_id": 0,
      "arxiv_id": {
        "$map": {
          "input": "$match_arxiv_id",
          "as": "m",
          "in": {
            "$arrayElemAt": [
              { "$split": [ "$$m.match", ":" ] },
              1
            ]
          }
        }
      }
    }
  }
  ]')
  )
  YIELD value
  // Add this WHERE clause to filter for non-empty arrays
  WHERE size(value.arxiv_id) > 0
  RETURN value;
