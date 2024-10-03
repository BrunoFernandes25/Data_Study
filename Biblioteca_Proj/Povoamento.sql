USE biblioteca;

INSERT INTO livros (titulo, autor, ano, disponibilidade) VALUES
('O Pequeno Príncipe', 'Antoine de Saint-Exupéry', 1943, TRUE),
('1984', 'George Orwell', 1949, TRUE),
('Dom Quixote', 'Miguel de Cervantes', 1605, TRUE),
('Orgulho e Preconceito', 'Jane Austen', 1813, TRUE),
('Cem Anos de Solidão', 'Gabriel García Márquez', 1967, TRUE),
('O Senhor dos Anéis', 'J.R.R. Tolkien', 1954, TRUE),
('O Hobbit', 'J.R.R. Tolkien', 1937, TRUE),
('Guerra e Paz', 'Liev Tolstói', 1869, TRUE),
('Crime e Castigo', 'Fiódor Dostoiévski', 1866, TRUE),
('A Revolução dos Bichos', 'George Orwell', 1945, TRUE),
('Moby Dick', 'Herman Melville', 1851, TRUE),
('Ulisses', 'James Joyce', 1922, TRUE),
('A Divina Comédia', 'Dante Alighieri', 1320, TRUE),
('O Grande Gatsby', 'F. Scott Fitzgerald', 1925, TRUE);
# select * from livros;

INSERT INTO users (nome, email, senha, tipo) VALUES 
('João Silva', 'joao@example.com', 'senha123', 'user'),
('Maria Oliveira', 'maria@example.com', 'senha456', 'admin'),
('Carlos Ferreira', 'carlos@example.com', 'senha789', 'user'),
('Ana Costa', 'ana@example.com', 'senha321', 'user'),
('Beatriz Lima', 'beatriz@example.com', 'senha654', 'admin'),
('Rafael Santos', 'rafael@example.com', 'senha987', 'user'),
('Paula Souza', 'paula@example.com', 'senha147', 'user');
# select * from users;