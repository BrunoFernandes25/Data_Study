CREATE DATABASE biblioteca;
# drop database biblioteca;
USE biblioteca;
#drop database biblioteca;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    tipo ENUM('user', 'admin') DEFAULT 'user',
    num_livros_emprestados INT NOT NULL DEFAULT 0,
    CONSTRAINT chk_livros_emprestados CHECK (num_livros_emprestados <= 1),
    penalizado_ate DATE DEFAULT NULL
);
#drop table users;

CREATE TABLE livros (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    autor VARCHAR(100) NOT NULL,
    ano INT NOT NULL,
    disponibilidade BOOLEAN DEFAULT TRUE
);
#drop table livros;

CREATE TABLE reservations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    id_livro INT,
    data_reserva TIMESTAMP DEFAULT CURRENT_TIMESTAMP,		-- data em que um livro é reservado/emprestado a um user
    status ENUM('pendente', 'aprovada', 'rejeitada') DEFAULT 'pendente',
    FOREIGN KEY (id_usuario) REFERENCES users(id),
    FOREIGN KEY (id_livro) REFERENCES livros(id)
);
#drop table reservations;

CREATE TABLE emprestimos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    id_livro INT,
    data_emprestimo TIMESTAMP DEFAULT CURRENT_TIMESTAMP,	-- quando é cedido um livro por emprestimo a um user
    data_devolucao DATE,									-- data que o user devolve o livro
    devolvido BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id_usuario) REFERENCES users(id),
    FOREIGN KEY (id_livro) REFERENCES livros(id)
);
#drop table emprestimos;