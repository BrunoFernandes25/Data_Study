USE biblioteca;

-- Visualização da tabela com o JOIN entre livros e os seus emprestimos
SELECT e.id AS emprestimo_id, e.id_usuario, e.id_livro, e.data_emprestimo, e.data_devolucao, e.devolvido,
       l.titulo, l.autor, l.ano, l.disponibilidade
FROM emprestimos e
JOIN livros l ON e.id_livro = l.id;

-- Visualização da tabela com o JOIN entre usuarios e os seus emprestimos
SELECT e.id AS emprestimo_id, e.id_usuario, e.id_livro, e.data_emprestimo, e.data_devolucao, e.devolvido,
       u.nome, u.email
FROM emprestimos e
JOIN users u ON e.id_usuario = u.id;

-- Visualização da tabela com o JOIN entre usuarios, os seus emprestimos e os livros
SELECT e.id AS emprestimo_id, e.id_usuario, e.id_livro, e.data_emprestimo, e.data_devolucao, e.devolvido,
       u.nome AS usuario_nome, u.email AS usuario_email,
       l.titulo AS livro_titulo, l.disponibilidade AS livro_disponibilidade
FROM emprestimos e
JOIN users u ON e.id_usuario = u.id
JOIN livros l ON e.id_livro = l.id;

-- QUERIES REALTIVAS À BIBLIOTECA

-- Livros já requisitados
SELECT 
    l.titulo AS livro, 
    COUNT(r.id_livro) AS num_requisicoes
FROM reservations r
JOIN livros l ON r.id_livro = l.id
GROUP BY r.id_livro;

-- Livro mais requisitado
SELECT 
    l.titulo AS livro, 
    COUNT(r.id_livro) AS num_requisicoes
FROM reservations r
JOIN livros l ON r.id_livro = l.id
GROUP BY r.id_livro
ORDER BY num_requisicoes DESC
LIMIT 1;

-- Top 3 Livros mais requisitados
SELECT 
    l.titulo AS livro, 
    COUNT(r.id_livro) AS num_requisicoes
FROM reservations r
JOIN livros l ON r.id_livro = l.id
GROUP BY r.id_livro
ORDER BY num_requisicoes DESC
LIMIT 3;

-- Numero de requisições por user
SELECT
	u.nome AS cliente,
	COUNT(e.id_usuario) as numero_livros
FROM  emprestimos e
JOIN users u ON e.id_usuario = u.id
GROUP BY e.id_usuario
ORDER BY cliente ASC;

-- Top users requisição de livros
SELECT
	u.nome AS cliente,
	COUNT(e.id_usuario) AS numero_livros
FROM  emprestimos e
JOIN users u ON e.id_usuario = u.id
GROUP BY e.id_usuario
ORDER BY numero_livros DESC
LIMIT 10;

-- Users com menor tempo de empréstimo de livros (em dias) 
SELECT 
    u.nome,
    SUM(DATEDIFF(e.data_devolucao, e.data_emprestimo)) AS total_tempo_devolucao
FROM 
    emprestimos e
JOIN 
    users u ON e.id_usuario = u.id
WHERE 
    e.devolvido = TRUE
    AND e.data_devolucao <= e.data_devolucao  -- Garantir que a devolução está dentro do prazo
GROUP BY 
    u.id, u.nome
ORDER BY 
    total_tempo_devolucao ASC
LIMIT 10;

