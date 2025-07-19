CALL apoc.periodic.iterate(
  "
  CALL apoc.mongo.aggregate(
    'mongodb://localhost:27017/arXiv.papers',
    apoc.convert.fromJsonList('[
      { \"$unwind\": { \"path\": \"$bib\", \"preserveNullAndEmptyArrays\": true} },
      { \"$addFields\":
          { \"match_arxiv_id\":
              { \"$ifNull\":
                  [
                      {\"$regexFind\": {
                          \"input\": \"$bib.journal\",
                          \"regex\": \"arXiv:\\\\d+\\\\.\\\\d+(v\\\\d+)?\",
                          \"options\": \"i\"
                      }},
                      {\"$regexFind\": {
                          \"input\": \"$bib.url\",
                          \"regex\": \"http(s)?://arxiv\\\\.org/abs/\\\\d+\\\\.\\\\d+(v\\\\d+)?\",
                          \"options\": \"i\"
                      }},
                      {\"$regexFind\": {
                          \"input\": \"$bib.booktitle\",
                          \"regex\": \"arXiv:\\\\d+\\\\.\\\\d+(v\\\\d+)?\",
                          \"options\": \"i\"
                      }},
                      {\"$regexFindAll\": {
                          \"input\": \"$bbl\",
                          \"regex\": \"arXiv:\\\\d+\\\\.\\\\d+(v\\\\d+)?|http(s)?://arxiv\\\\.org/abs/\\\\d+\\\\.\\\\d+(v\\\\d+)?\",
                          \"options\": \"i\"
                      }}
                  ]
              }
          }
      },
      { \"$unwind\": { \"path\": \"$match_arxiv_id\", \"preserveNullAndEmptyArrays\": true} },
      { \"$unwind\": { \"path\": \"$authors\" } },
      { \"$unwind\": { \"path\": \"$categories\" } },
      { \"$project\": {
          \"_id\": 0,
          \"title\": 1,
          \"id\": 1,
          \"name\": \"$authors\",
          \"category\": \"$categories\",
          \"citation_title\": \"$bib.title\",
          \"arxiv_id\": { \"$ifNull\":
              [
                  { \"$cond\":
                      { \"if\":
                          { \"$or\":
                              [
                                  { \"$eq\": [{ \"$toLower\": \"$bib.eprinttype\" }, \"arxiv\"] },
                                  { \"$eq\": [{ \"$toLower\": \"$bib.archiveprefix\" }, \"arxiv\"] }
                              ]
                          },
                          \"then\": \"$bib.eprint\",
                          \"else\": null
                      }
                  },
                  {\"$arrayElemAt\": [ { \"$split\": [{ \"$arrayElemAt\": [ { \"$split\": [\"$match_arxiv_id.match\", \"/\"] }, -1 ] }, \":\"] }, -1 ]}
              ]}
      }}
    ]')
  )
  YIELD value
  RETURN value
  ",

  "
  MERGE (p:Paper {id: value.id})
    ON CREATE SET p.title = value.title
    ON MATCH SET p.title = value.title
  MERGE (a:Author {name: value.name})
  MERGE (c:Category {category: value.category})
  MERGE (a)-[:WROTE]->(p)
  MERGE (p)-[:CATEGORY]-(c)
  MERGE (p)-[:WRITTEN_BY]->(a)

  WITH p, value
  WHERE value.arxiv_id IS NOT NULL
  MERGE (p2:Paper {id: value.arxiv_id})
    ON CREATE SET p2.title = value.citation_title
  MERGE (p)-[:CITES]->(p2)
  MERGE (p2)-[:IS_CITED_BY]->(p)
  ",

  {batchSize: 1000, parallel: false}
)
