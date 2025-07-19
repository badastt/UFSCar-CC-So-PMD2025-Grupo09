

# Projeto de Disciplina - Rede de Artigos Científicos do arXiv

### Universidade Federal de São Carlos
### Curso: Bacharelado em Ciência da Computação de Sorocaba
### Disciplina: Processamento Massivo de Dados
### Professora: Profª. Drª. Sahudy Montenegro González

## 

### Grupo 9
### Integrantes:
 - Beatriz Rogers Tripoli Barbosa (792170)
 - Jean Rodrigues Rocha (813581)
 - Thiago Domingues da Silva (802276)

##

## 1. Resumo
Foi criado um sistema de dados baseado em nós usando as ferramentas Neo4j e MongoDB, relacionando artigos, categorias e autores. Nosso sistema contém os dados em forma bruta guardados no MongoDB e, através de comandos do plugin para Neo4j APOC, inserimos todos os papéis, autores e categorias no sistema do Neo4j, além disso foram criados relacionamentos de citação entre os artigos, de escrita entre papéis e autores e de categorias entre categorias e artigos. 

## 2. Introdução
Nota-se a existência de sistemas de banco de dados para artigos científicos, porém, com fins educativos, decidimos criar  um sistema de banco de dados com foco nos relacionamentos dos artigos,  facilitando consultas relacionadas a um artigo específico e suas citações, trabalhos de autores particulares e seus colaboradores, ou procurando em categorias mais abrangentes.

O foco principal do projeto foi se familiarizar com sistemas de bancos de dados NoSQL, especificamente integrando duas tecnologias distintas em um uso. Assim, para garantir a permanência dos dados e facilitar o  tratamento necessário dos mesmos, foi decidido utilizar o MongoDB para guardar os dados brutos, enquanto o Neo4j foi utilizado para o estabelecimento do banco de dados tratado com os relacionamentos estruturados.

## 3. Planejamento Inicial
Inicialmente, previa-se que teríamos informações sobre o título, autores, palavras-chaves, categorias e citações de todos os artigos disponíveis no arXiv, porém, observamos que o uso de palavras-chaves não é padronizado, portanto, não seríamos capazes de obter essas informações para todos os artigos, e quando fossemos capazes, o processo iria envolver processar o código fonte tex para encontrar as palavras-chaves.

Portanto, ainda na primeira entrega, mudamos o escopo para trabalharmos com id, link, data da última atualização, data de publicação, título, autores, resumo, categorias, código fonte tex, bibtex (se houver) e bbl (se houver). Esses dados seriam obtidos através da API do arXiv para python e carregados do mongoDB, do qual os dados referentes à título, autores, categorias e citações seriam processados e usados para preencher o banco de dados do Neo4j.

Todo esse fluxo de dados e planejamento pode ser observado no fluxograma abaixo:
	
![fluxograma](https://github.com/badastt/UFSCar-CC-So-PMD2025-Grupo09/blob/main/images/Fluxograma_PMD.png "Fluxograma")

Observe que o papel do MongoDB nessa aplicação é atuar como um banco de dados no qual serão armazenados todos os dados brutos que idealmente não serão usados com frequência nas consultas, porém, sempre está disponível por meio de um drill-through através do neo4j para o MongoDB. Enquanto isso, o papel do Neo4j é atuar como uma representação em grafos dos relacionamentos dos artigos, usando dados já processados e formatados em um modelo apropriado. 

## 4. Objetivos
O objetivo principal deste projeto é construir uma rede de relacionamentos entre artigos científicos, mais especificamente, relacionando os artigos com os seus autores, suas categorias e as suas citações. O motivo por trás da criação da rede considera a dificuldade em procurar artigos relacionados com os tópicos que alguém possa estar pesquisando. É consideravelmente trabalhoso procurar manualmente pelas citações de um artigo para tentar encontrar outros trabalhos que tenham um assunto parecido. Ao criar uma rede dessa forma, torna-se mais prático procurar artigos interessantes para um pesquisa, sendo que a busca pode ser feita pelas citações, categorias, e até mesmo pelos autores.

Em resumo, as motivações iniciais surgiram com base nas experiências da dificuldade de encontrar artigos científicos que cumpram certos critérios e estejam relacionados a um tópico específico (pelo menos pela experiência de um dos membros do grupo…) e pensando no quão mais prático seria usar uma ferramenta que consiga organizar a busca de outros trabalhos científicos assim.


## 5. Fundamentação Teórica
Os dados brutos usados nesse projeto podem ser facilmente obtidos através da API, porém, esse processo é demorado pois envolve acessar o site do arXiv, baixar o código fonte do artigo e processar as informações obtidas, portanto, é de nosso interesse manter os dados brutos armazenados em algum lugar. Desta forma, decidimos escolher o MongoDB como banco de dados para cumprir com esse papel, não só por estarmos mais familiarizados, mas também por ser uma tecnologia orientada à documentos com um comando que permite processar os dados de diversas formas convenientes (aggregate). Como os dados brutos são muito maiores que os dados processados (autores, títulos, categorias e citações), também faz sentido usar um banco de dados que tenha capacidade de paralelizar o acesso aos dados de maneira mais natural, visto que o MongoDB foi pensado para ser eficiente em uma arquitetura horizontal, enquanto o Neo4J foi pensado para ser eficiente em uma arquitetura vertical. No nosso caso, não temos dados o suficiente para ser necessário armazená-los em diversas máquinas, mas para um projeto de escala maior, provavelmente seria melhor dividir os dados em diversas máquinas.

Passando para o outro banco de dados utilizados, a escolha de se utilizar o Neo4J se principalmente pelo fato da tecnologia ser orientada à grafos, visto que esse tipo de tecnologia é a mais apropriada para cumprir com o propósito de construir uma rede de relacionamentos entre artigos científicos, além disso, não podemos desconsiderar a facilidade de uso como outro dos nossos principais motivos para a escolha da tecnologia. Além disso, também foi trazido para nossa atenção o plugin APOC para realizar a integração entre MongoDB e Neo4j, solidificando a ferramenta como nossa escolha.

## 6. Desenvolvimento

### Extração dos dados com Python
A mineração dos dados se deu de maneira consideravelmente simples, visto que existe uma API do arXiv para python, então só foi necessário aprender a usá-la e projetar um código que nos permita obter uma quantidade considerável de códigos.

A API possui uma função chamada “download_source”, que nos permite baixar o código fonte tex, bibtex e bbl que foram usados para gerar o pdf dos artigos porém, ele não estava funcionando adequadamente no windows, então foi necessário fazer o seguinte fix:

```Python
ssl_context = ssl.create_default_context(cafile=certifi.where())
original_urlopen = urllib.request.urlopen

def patched_urlopen(url, *args, **kwargs):
    if 'context' not in kwargs:
        kwargs['context'] = ssl_context
    return original_urlopen(url, *args, **kwargs)

urllib.request.urlopen = patched_urlopen
```

Como o mongoDB tem uma limitação em relação ao tamanho dos documentos que ele pode importar, foi desenvolvido um código para quebrar os arquivos ndjson em arquivos de até 10MB (a não ser quando isso não fosse possível), caso fosse necessário rodar o código diversas vezes, o ideal seria que os artigos já minerados fossem ignorados, portanto, o seguinte código foi usado:

```Python
chunks = list(Path("papers").glob("data_chunk_*.ndjson"))
chunk_index += len(chunks)

for chunk in chunks:
    with open(chunk, 'r', encoding='utf-8') as f:
        papers = [json.loads(line) for line in f]
        for p in papers:
            mined.add(p["id"])

client = arxiv.Client()

categories = [
    "cs.AI", "cs.AR", "cs.CC", "cs.CE", "cs.CG", "cs.CL", "cs.CR", "cs.CV", "cs.CY", "cs.DB"
]

categories = [  
                "cs.AI", "cs.AR", "cs.CC", "cs.CE", "cs.CG", "cs.CL", "cs.CR", "cs.CV", "cs.CY", "cs.DB",
                "cs.DC", "cs.DL", "cs.DM", "cs.DS", "cs.ET", "cs.FL", "cs.GL", "cs.GR", "cs.GT", "cs.HC",
                "cs.IR", "cs.IT", "cs.LG", "cs.LO", "cs.MA", "cs.MM", "cs.MS", "cs.NA", "cs.NE", "cs.NI",
                "cs.OH", "cs.OS", "cs.PF", "cs.PL", "cs.RO", "cs.SC", "cs.SD", "cs.SE", "cs.SI", "cs.SY",
                "econ.EM", "econ.GN", "econ.TH", "eess.AS", "eess.IV", "eess.SP", "eess.SY", "math.AC", "math.AG", "math.AP",
                "math.AT", "math.CA", "math.CO", "math.CT", "math.CV", "math.DG", "math.DS", "math.FA", "math.GM", "math.GN",
                "math.GR", "math.GT", "math.HO", "math.IT", "math.KT", "math.LO", "math.MG", "math.MP", "math.NA", "math.NT",
                "math.OA", "math.OC", "math.PR", "math.QA", "math.RA", "math.RT", "math.SG", "math.SP", "math.ST", "astro-ph.CO",
                "astro-ph.EP", "astro-ph.GA", "astro-ph.HE", "astro-ph.IM", "astro-ph.SR", "cond-mat.dis-nn", "cond-mat.mes-hall", "cond-mat.mtrl-sci", "cond-mat.other",
                "cond-mat.quant-gas", "cond-mat.soft", "cond-mat.stat-mech", "cond-mat.str-el", "cond-mat.supr-con", "gr-qc", "hep-ex", "hep-lat", "hep-ph", "hep-th",
                "math-ph", "nlin.AO", "nlin.CD", "nlin.CG", "nlin.PS", "nlin.SI", "nucl-ex", "nucl-th", "physics.acc-ph", "physics.ao-ph",
                "physics.app-ph", "physics.atm-clus", "physics.atom-ph", "physics.bio-ph", "physics.chem-ph", "physics.class-ph", "physics.comp-ph", "physics.data-an", "physics.ed-ph", "physics.flu-dyn",
                "physics.gen-ph", "physics.geo-ph", "physics.hist-ph", "physics.ins-det", "physics.med-ph", "physics.optics", "physics.plasm-ph", "physics.pop-ph", "physics.soc-ph", "physics.space-ph",
                "quant-ph", "q-bio.BM", "q-bio.CB", "q-bio.GN", "q-bio.MN", "q-bio.NC", "q-bio.OT", "q-bio.PE", "q-bio.QM", "q-bio.SC",
                "q-bio.TO", "q-fin.CP", "q-fin.EC", "q-fin.GN", "q-fin.MF", "q-fin.PM", "q-fin.PR", "q-fin.RM", "q-fin.ST", "q-fin.TR",
                "stat.AP", "stat.CO", "stat.ME", "stat.ML", "stat.OT", "stat.TH"
            ]

for n, c in enumerate(categories, 1):
    print(f"Fetching IDs for category {n} / {len(categories)}: {c}")
    search = arxiv.Search(
        query = f"cat:{c}",
        max_results=50,
        sort_by=arxiv.SortCriterion.SubmittedDate
    )
    try:
        results = client.results(search)
        for paper in results:
            pid = paper.entry_id.rsplit('/', 1)[-1].rsplit('v', 1)[0]
            all_paper_ids.add(pid)
    except Exception as e:
        print(f"Error fetching from category {c}: {e}")

all_paper_ids -= mined

print(f"Total paper IDs collected after removing repeated or mined: {len(all_paper_ids)}")
```

Na primeira parte do código, todos os ids dos artigos já minerados são recuperados dos ndjsons. Na segunda parte, são pegos os ids de diversos artigos de 155 categorias diferentes usando a API do arXiv. Alguns ids terminam com “vx”, onde “x” é um número, mas como a versão dos artigos não era interessante para a gente, nós removemos isso. Após pegar todos os ids, os ids que já tinham sido minerados são removidos de all_paper_ids.


A função “process_paper” foi feita para salvar os metadados de um artigo com base no seu id, além de fazer o download do seu código fonte, salvar o arquivo tex principal, encontrar o arquivo bibtex ou bbl e salvar as referências:

```Python
def process_paper(id):
    try:
        r = next(client.results(arxiv.Search(id_list=[id])))

        data = {}
        data['id'] = id
        data['link'] = r.entry_id
        data['last_update'] = r.updated.isoformat()
        data['published'] = r.published.isoformat()
        data['title'] = r.title
        data['authors'] = [str(a) for a in r.authors]
        data['summary'] = r.summary
        data['primary_category'] = r.primary_category
        data['categories'] = r.categories
        data['pre-print_link'] = f"http://arxiv.org/e-print/{id}"

        paper_path = os.path.join(download_dir, f"{id}.tar.gz")
        r.download_source(dirpath=download_dir, filename=f"{id}.tar.gz")

        extracted_path = os.path.join(extracted_dir, id)
        os.makedirs(extracted_path, exist_ok=True)

        try:
            with tarfile.open(paper_path, "r:gz") as tar:
                tar.extractall(path=extracted_path, filter='data')
    
            bib_entries = []
            for root, _, files in os.walk(extracted_path):
                for file in files:
                    if file.endswith('.bib'):
                        try:
                            with open(os.path.join(root, file), encoding='utf-8') as f:
                                parser = bibtexparser.bparser.BibTexParser(common_strings=True, ignore_nonstandard_types=True)
                                bib_db = bibtexparser.load(f, parser=parser)
                                bib_entries.extend(bib_db.entries)
                        except Exception as e:
                            print(f"{id} - .bib error: {e}")
            if bib_entries:
                data['bib'] = bib_entries
            else:
                for root, _, files in os.walk(extracted_path):
                    for file in files:
                        if file.endswith('.bbl'):
                            try:
                                with open(os.path.join(root, file), encoding='utf-8') as f:
                                    data['bbl'] = f.read()
                            except Exception as e:
                                print(f"{id} - .bbl error: {e}")
                            break
    
            for root, _, files in os.walk(extracted_path):
                for file in files:
                    if file.endswith('.tex'):
                        try:
                            with open(os.path.join(root, file), encoding='utf-8') as f:
                                tex = f.read()
                                if re.search(r"\*?\\documentclass\*?", tex):
                                    data['tex'] = tex
                                    break
                        except Exception as e:
                            print(f"{id} - .tex error: {e}")
        except:
            pass

        try:
            if os.path.exists(paper_path):
                os.remove(paper_path)
            if os.path.exists(extracted_path):
                shutil.rmtree(extracted_path)
        except Exception as e:
            print(f"{id} - cleanup error: {e}")

        return data

    except Exception as e:
        print(f"{id} - general error: {e}")
        return { "id": id, "error": str(e) }
```

Por fim, o ThreadPoolExecutor foi usado para processar diversos papers paralelamente e para fazer um dump do json toda vez que o tamanho dele passar de 10MB:

```Python
with ThreadPoolExecutor(max_workers=10) as executor:
    futures = [executor.submit(process_paper, pid) for pid in all_paper_ids]
    for future in as_completed(futures):
        result = future.result()
        pid = result.get("id", "[unknown]")

        if not result or "error" in result:
            continue
        
        if "error" not in result:
            all_data[pid] = result
            print(f"{pid}: {result.get('title', '[no title]')}")

            est_size = len(json.dumps(all_data, ensure_ascii=False).encode("utf-8"))

            print(f"{est_size} / {MAX_BYTES}")
            
            if est_size > MAX_BYTES:
                all_data.pop(pid)
                filename = os.path.join(output_dir, f"data_chunk_{chunk_index:03d}.ndjson")
                with open(filename, "w", encoding="utf-8") as f:
                    for paper_id, metadata in all_data.items():
                        metadata["id"] = paper_id
                        json.dump(metadata, f)
                        f.write("\n")
                chunk_index += 1
                all_data = {pid: result}
```

No geral, o código usado para minerar os dados é consideravelmente simples, houve alguns pequenos problemas na construção dele, mas nada que não pudesse ser facilmente contornado.

### MongoDB

Como o MongoDB foi usado principalmente para armazenar os dados brutos, o único processo que foi realmente necessário para utilizá-lo foi a importação dos dados. Para tal, escrevemos um shell script que carrega todos os arquivos ndjsons gerados pelo código de mineração de dados:

```Shell
#!/bin/bash

DB_NAME="arXiv"
COLLECTION="papers"

for file in $(ls data_chunk_*.ndjson 2>/dev/null | sort -V); do
    mongoimport --db "$DB_NAME" --collection "$COLLECTION" --file "$file" --type=json
done
```

Há uma consulta do MongoDB que foi desenvolvida para processar os dados, sendo que o banco de dados foi chamado através do APOC, permitindo assim, inserir diretamente os dados no Neo4j, mas isso será tratado na próxima seção.

### Neo4j

O código do Neo4j (Cypher) é o seguinte:
```Cypher
CALL apoc.mongo.aggregate(
    "mongodb://localhost:27017/arXiv.papers",
    apoc.convert.fromJsonList('COMANDO_MONGO')
)
YIELD value
MERGE (p:Paper {id: value.id})
ON CREATE SET p.title = value.title
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
MERGE (p2)-[:IS_CITED_BY]->(p);
```
Nele obtemos os dados do mongodb usando o APOC, só que antes de pegarmos os dados brutos como estão, processamos um pouco.

Antes disso, o COMANDO_MONGO é
```JSON
[
    { "$unwind": { "path": "$bib", "preserveNullAndEmptyArrays": true} },
    { "$addFields":
        { "match_arxiv_id":
            { "$ifNull":
                [
                    {"$regexFind": {
                        "input": "$bib.journal",
                        "regex": "arXiv:\\\\d+\\\\.\\\\d+(v\\\\d+)?",
                        "options": "i"
                    }},
                    {"$regexFind": {
                        "input": "$bib.url",
                        "regex": "http(s)?://arxiv\\\\.org/abs/\\\\d+\\\\.\\\\d+(v\\\\d+)?",
                        "options": "i"
                    }},
                    {"$regexFind": {
                        "input": "$bib.booktitle",
                        "regex": "arXiv:\\\\d+\\\\.\\\\d+(v\\\\d+)?",
                        "options": "i"
                    }},
                    {"$regexFindAll": {
                        "input": "$bbl",
                        "regex": "arXiv:\\\\d+\\\\.\\\\d+(v\\\\d+)?|http(s)?://arxiv\\\\.org/abs/\\\\d+\\\\.\\\\d+(v\\\\d+)?",
                        "options": "i"
                    }}
                ]
            }
        }
    },
    { "$unwind": { "path": "$match_arxiv_id", "preserveNullAndEmptyArrays": true} },
    { "$unwind": { "path": "$authors" } },
    { "$unwind": { "path": "$categories" } },
    { "$project": {
        "_id": 0,
        "title": 1,
        "id": 1,
        "name": "$authors",
        "category": "$categories",
        "citation_title": "$bib.title",
        "arxiv_id": { "$ifNull":
            [
                { "$cond":
                    { "if":
                        { "$or":
                            [
                                { "$eq": [{ "$toLower": "$bib.eprinttype" }, "arxiv"] },
                                { "$eq": [{ "$toLower": "$bib.archiveprefix" }, "arxiv"] }
                            ]
                        },
                        "then": "$bib.eprint",
                        "else": null
                    }
                },
                {"$arrayElemAt": [ { "$split": [{ "$arrayElemAt": [ { "$split": ["$match_arxiv_id.match", "/"] }, -1 ] }, ":"] }, -1 ]}
            ]}
    }}
]
```
No pipeline de agregação, primeiro fazemos um unwind do campo 'bib', pois precisamos criar um nó 'Paper' para cada uma das citações desse campo. O preserveNullAndEmptyArrays serve para não executar o comportamento padrão do unwind que seria remover as entradas que não possuem o campo (ou possuem ele com valor null ou array vazio).
Em seguida executamos vários regexFind sendo um deles um regexFindAll porque o campo do 'bbl' não é uma lista como o 'bib', e sim somente uma string gigante. Esses regexes são usados para obter o id dos artigos que são citados pelos artigos obtidos na mineração, sejam eles links (https://arxiv.org/abs/*) ou ids (arXiv:id). Adicionamos o resultado deles em um campo novo chamado 'match_arxiv_id', pois ainda precisamos tirar a parte do 'https://arxiv.org/abs/' ou 'arXiv:’. O ifNull é usado para encadear as operações de regex caso algum dos campos (bib.journal, bib.url, bib.booktitle) não estejam presentes.
Em seguida executamos mais unwinds. O do 'match_arxiv_id' serve para separar as citações da lista obtida pelo regexFindAll (nos artigos que possuem 'bbl'), com a opção de preserveNullAndEmptyArrays para não remover os que não possuem o 'bbl'. O do 'authors' e 'categories' para poder separar cada um desses campos em sua própria entrada, já que também criamos nós para eles no Neo4j, então precisamos deles separados também.
Na projeção, removemos o '_id' do mongodb, já que não o usamos. O 'title' e 'id' são usados no nó 'Paper', o 'name' é usado no nó 'Author', o 'category' é usado no nó 'Category'. Os últimos dois campos 'citation_title' e 'arxiv_id' são usados para criar os nós 'Paper' a partir das citações, também os usamos para criar as relações de 'CITES' e 'IS_CITED_BY'. Como as citações podem vir do 'bib' (no journal, booktitle, url, eprintype ou archiveprefix) ou do 'bbl' usamos um ifNull combinado com um cond para decidir como preencher o campo. Os split são usados para separar o 'arXiv:' ou o resto do html do id do artigo.
Finalmente, no Neo4j então criamos os nós 'Paper', 'Author' e 'Category', com as relações 'WROTE', 'WRITTEN_BY' e 'CATEGORY' usando os dados mostrados anteriormente.
A criação do 'CITES' e 'IS_CITED_BY' estão separados para poder checar com 'WITH p, value WHERE value.arxiv_id IS NOT NULL' se o valor não é nulo antes de criar o resto dos 'Paper's com as relações.

Além do comando principal utilizado para adicionar os dados no sistema do Neo4J, foram criados índices para facilitar a inserção/atualização de dados além de diminuir o tempo de resposta das consultas:

```Cypher
CREATE INDEX paper_id IF NOT EXISTS FOR (p:Paper) ON (p.id);
CREATE INDEX author_name IF NOT EXISTS FOR (a:Author) ON (a.name);
CREATE INDEX categories_category IF NOT EXISTS FOR (c:Category) ON (c.category);
```

A seguinte imagem mostra uma parte dos dados importados no Neo4j, vale mencionar que alguns fatores limitaram a quantidade de nós e arcos nessa imagem, como limites de exibição de nós do próprio Neo4j:

![grafo](https://github.com/badastt/UFSCar-CC-So-PMD2025-Grupo09/blob/main/images/all_nodes.png "Grafo")


A seguir estão algumas consultas que são possíveis e esperadas com o sistema feito:

1. Consulta para encontrar a partir de um nome de autor, todos os artigos escritos por ele que possuem colaboradores, além de quem são os colaboradores:
```Cypher
MATCH (a:Author{name:"Onur Mutlu"})-[:WROTE]->(p:Paper)-[wb:WRITTEN_BY]->(coauthor:Author)
WHERE a <> coauthor
RETURN coauthor, p, wb
```

![consulta_1](https://github.com/badastt/UFSCar-CC-So-PMD2025-Grupo09/blob/main/images/consulta_1.png "Consulta 1")


2. Consulta para encontrar os artigos mais frequentemente citados dentro do banco de dados:
```Cypher
MATCH w=(p)-[:IS_CITED_BY]->()
RETURN p.id AS PaperId, count(w) AS NumberOfCitations
ORDER BY NumberOfCitations DESC
LIMIT 10
```

![consulta_2](https://github.com/badastt/UFSCar-CC-So-PMD2025-Grupo09/blob/main/images/consulta_2.png "Consulta 2")


3. Consulta para encontrar os autores que escreveram mais artigos e suas colaborações mais frequentes:
```Cypher
MATCH (a1:Author)-[:WROTE]->(p:Paper)<-[:WROTE]-(a2:Author)
WHERE elementId(a1) < elementId(a2)
WITH a1, a2, count(p) AS collaborations
ORDER BY collaborations DESC
LIMIT 10
RETURN a1.name AS Author1, a2.name AS Author2, collaborations AS PapersWrittenTogether
```

![consulta_3](https://github.com/badastt/UFSCar-CC-So-PMD2025-Grupo09/blob/main/images/consulta_3.png "Consulta 3")


4. Consulta para encontrar artigos que contém duas categorias distintas, indicando uma pesquisa interdisciplinar:
```Cypher
MATCH (c1:Category {category: 'cs.AI'})<-[:CATEGORY]-(p:Paper)-[:CATEGORY]->(c2:Category {category: 'q-bio.NC'})
RETURN p.title AS PaperTitle, p.id AS PaperID
```

![consulta_4](https://github.com/badastt/UFSCar-CC-So-PMD2025-Grupo09/blob/main/images/consulta_4.png "Consulta 4")


5. Consulta para encontrar a maior sequência de citações entre artigos:
```Cypher
MATCH path = (start_paper:Paper)-[:CITES*]->(end_paper:Paper)
WHERE start_paper <> end_paper
RETURN
    start_paper.id AS StartingPaper,
    end_paper.id AS EndingPaper,
    length(path) AS CitationPathLength,
    [p in nodes(path) | p.id] AS PathOfPapers
ORDER BY CitationPathLength DESC
LIMIT 1
```

![consulta_5](https://github.com/badastt/UFSCar-CC-So-PMD2025-Grupo09/blob/main/images/consulta_5.png "Consulta 5")


## 7. Dificuldades encontradas
Foram encontradas dificuldades em diversas partes, mas principalmente na integração do Mongodb com o Neo4j. Pois para que isso seja possível é necessário o uso do [APOC](https://neo4j.com/docs/apoc/current/), só que não bastava somente baixar o [núcleo](https://github.com/neo4j/apoc/releases) dele, já que a [função do mongo](https://neo4j.com/labs/apoc/5/overview/apoc.mongo/) pertence ao "APOC Extended" que está presente em [outro repositório](https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases) e que também necessitava de baixar o "apoc-mongodb-dependencies-*.jar", nada disso que era imediatamente explícito em qualquer lugar, e que foi descoberto por bastante pesquisa e tentativa-e-erro.
Mesmo tendo o código do APOC agora funcionando, fazer o "regexFind" funcionar também não foi trivial, já que ao tentar rodar o código que logicamente faria sentido e.g.:
```
{"$regexFind": {
    "input": "$bib.journal",
    "regex": "arXiv:\d+\.\d+(v\d+)?",
    "options": "i"
}}
```
Isso não funciona, e os erros que o cypher-shell devolvia eram completamente enigmáticos e não ajudavam em nenhuma forma a saber o que estava de errado com o programa.
Foi depois de muita pesquisa e tentativa-e-erro que descobrimos que o certo era colocar:
```
{"$regexFind": {
    "input": "$bib.journal",
    "regex": "arXiv:\\\\d+\\\\.\\\\d+(v\\\\d+)?",
    "options": "i"
}}
```
Com quatro barras invertidas ao invés de uma (ou duas), o que não fazia nenhum sentido lógico, só que pela forma que os 'escape characters' funcionam na combinação de usar uma função do APOC no cypher-shell para rodar na agregação do mongodb era necessário para poder rodar o regex corretamente.

## 8. Conclusões
O nosso planejamento inicial foi atingido, criamos uma rede de relacionamentos entre artigos científicos incluindo os artigos que eles citam, os artigos que eles são citados por, os autores e as suas categorias. Também conseguimos seguir o nosso fluxograma inicial (nenhuma consulta com o drill through foi projetada, mas a ideia foi usada para fazer a inserção dos dados no neo4j, então confirmamos seu funcionamento), com os dados passando por uma estrutura de camadas, possuindo os dados brutos no MongoDB e os relacionamentos processados no Neo4j, sendo possível ainda acessar o MongoDB através do Neo4j. 
Assim, com o sistema estabelecido, é possível realizar consultas procurando artigos que se citam, autores e colaboradores específicos ou por categorias mais abrangentes rápida e eficientemente, além disso, é possível acessar os dados brutos a partir do Neo4j utilizando o APOC, porém estas consultas não são as principais e serão inevitavelmente menos eficientes.
