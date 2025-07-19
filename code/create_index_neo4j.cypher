CREATE INDEX paper_id IF NOT EXISTS FOR (p:Paper) ON (p.id);
CREATE INDEX author_name IF NOT EXISTS FOR (a:Author) ON (a.name);
CREATE INDEX categories_category IF NOT EXISTS FOR (c:Category) ON (c.category);

