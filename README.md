# UFSCar-CC-So-PMD2025-Grupo09

## 1. Objetivo:

### 1.1. O que vai ser feito?
Será feita uma rede de relacionamentos entre artigos científicos, especificamente, vamos relacionar os títulos dos artigos científicos com seus autores, suas categorias, suas citações e artigos que o citam.

### 1.2. O que queremos atingir?
Redes com funcionalidade similares já existem, porém gostaríamos de não só entender profundamente seu funcionamento, ao criar um sistema do zero, como também introduzir o relacionamento específico de artigos citados e artigos que o citam. Como forma de aprimorar nosso aprendizado em tecnologias de Banco de Dados NoSQL, decidimos utilizar uma tecnologia orientada à documentos, para guardar informações mais detalhadas de cada artigo e uma tecnologia orientada à  grafos para estabelecer os relacionamentos somente dos itens cujos relacionamentos nos interessam.
		
## 2. Tecnologias:

As tecnologias utilizadas serão MongoDB e Neo4j.

### 2.1. Por que MongoDB?
Ao adquirir os dados da API e passar por um breve processo de pré-formatação será necessário extrair as categorias e autores de cada artigo como nós de tipos distintos para inserí-los no Neo4j. Além disso, no Neo4j não pretendemos guardar todos os dados, mas sim somente os que apresentam relacionamentos entre si, sendo necessário relacioná-lo com a base do MongoDB caso queira outros detalhes dos artigos. Além disso, MongoDB é a tecnologia orientada à grafos com a qual estamos mais familiarizados, por isso a escolha específica desta tecnologia.

### 2.2. Por que Neo4j?
Como precisamos de uma tecnologia orientada à grafos para estabelecer o relacionamento entre nós, ao escolher uma tecnologia para este propósito, consideramos a visualização dos grafos do Neo4j e a facilidade de uso são dois dos maiores motivos para a sua utilização. 

## 3. Fonte de dados:
Os dados vão ser adquiridos através da API do arXiv para Python, onde serão pré-formatados como json para serem usados no MongoDB. Os dados extraídos serão o id, link para o artigo, a data da última atualização, a data de publicação, o título, os autores, o resumo, as categorias, e o arquivo tex fonte (incluindo referências).

Esses dados extraídos serão colocados no mongoDB, além disso, parte dos dados serão processados para serem usados no Neo4j, isso incluí os títulos, ids, categorias e as citações. 

## 4. Fluxograma:
![fluxograma](https://github.com/badastt/UFSCar-CC-So-PMD2025-Grupo09/blob/main/images/Fluxograma_PMD.png "Fluxograma")
