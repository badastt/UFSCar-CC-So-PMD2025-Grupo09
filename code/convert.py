import json

with open("data.json", "r", encoding="utf-8") as f:
    data = json.load(f)

with open("papers.ndjson", "w", encoding="utf-8") as f_out:
    for paper_id, metadata in data.items():
        metadata["id"] = paper_id  # Add the ID into the object
        json.dump(metadata, f_out)
        f_out.write("\n")
