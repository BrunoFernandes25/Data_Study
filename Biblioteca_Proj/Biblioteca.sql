USE biblioteca;

#	PROCEDURES

DELIMITER $$
CREATE PROCEDURE EmprestarLivro(IN p_id_usuario INT, IN p_id_livro INT)
BEGIN
	
    DECLARE v_tipo_usuario ENUM('user', 'admin');	-- variavel para testar tipo de user
    DECLARE v_max_livros INT;						-- variavel para testar num_max_livros permitidos por user
	DECLARE v_penalizado_ate DATE;                 -- variável para armazenar a data da penalidade
    DECLARE v_mensagem_erro VARCHAR(255);
    DECLARE v_prazo_devolucao DATE;                 -- Variável para a data de devolução do livro
    
    -- Obter o tipo de User
	SELECT tipo INTO v_tipo_usuario FROM users WHERE id = p_id_usuario;
    
    -- Obter a data de penalização
    SELECT penalizado_ate INTO v_penalizado_ate FROM users WHERE id = p_id_usuario;
    
    -- Definir o número máximo de livros que o usuário pode emprestar
    SET v_max_livros = IF(v_tipo_usuario = 'admin', 3, 1);		-- se for admin pode requisitar 3 livros(pois é trabalhador da biblioteca se for um user comum apenas 1 livro
	
	-- Caso de verificação de penalidade de quem quer requisitar
	IF v_penalizado_ate > CURDATE() THEN
        -- Verificar se a penalização é permanente
		IF v_penalizado_ate = '9999-12-31' THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Proibido de requisitar mais livros nesta biblioteca.';
		ELSE
			SET v_mensagem_erro = CONCAT('Usuário está penalizado e não pode requisitar livros até ', v_penalizado_ate);
            SIGNAL SQLSTATE '45000'  SET MESSAGE_TEXT = v_mensagem_erro;
        END IF;
    END IF;
    
    -- Verificar se o livro está disponível
    IF (SELECT disponibilidade FROM livros WHERE id = p_id_livro) = TRUE THEN
        -- Verificar se o usuário já atingiu o limite de livros emprestados
        IF (SELECT COUNT(*) FROM emprestimos WHERE id_usuario = p_id_usuario AND devolvido = FALSE) < v_max_livros THEN
            -- Verificar se há uma reserva pendente para o livro
            IF (SELECT COUNT(*) FROM reservations WHERE id_usuario = p_id_usuario AND id_livro = p_id_livro AND status = 'pendente') > 0 THEN
                -- Aprovar a reserva pendente
                UPDATE reservations SET status = 'aprovada' WHERE id_usuario = p_id_usuario AND id_livro = p_id_livro AND status = 'pendente';
            
            ELSE
                -- Se não houver reserva pendente, criar uma nova reserva
                INSERT INTO reservations (id_usuario, id_livro, status) VALUES (p_id_usuario, p_id_livro, 'aprovada');
            END IF;

			-- Definir o prazo de devolução (2 meses a partir da data atual)
            SET v_prazo_devolucao = DATE_ADD(CURDATE(), INTERVAL 2 MONTH);

            -- Inserir registo do empréstimo
            INSERT INTO emprestimos (id_usuario, id_livro, data_devolucao) VALUES (p_id_usuario, p_id_livro, v_prazo_devolucao);

            -- Atualizar a disponibilidade do livro para FALSE (indisponível)
            UPDATE livros SET disponibilidade = FALSE WHERE id = p_id_livro;

            -- Atualizar o número de livros emprestados
            UPDATE users SET num_livros_emprestados = num_livros_emprestados + 1 WHERE id = p_id_usuario;
        ELSE
            -- Exibir mensagem de erro se o usuário já tem um livro emprestado
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: O usuário já tem um livro emprestado';
        END IF;

    ELSE
        -- Exibir mensagem de erro se o livro não estiver disponível mas adicionar às reservations como pedido pendente
        INSERT INTO reservations(id_usuario, id_livro, status) VALUES (p_id_usuario,p_id_livro,'pendente');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'O livro não está disponível. Pedido registrado como reserva pendente.';
    END IF;
END $$
DELIMITER ;
# drop procedure EmprestarLivro;

DELIMITER $$
CREATE PROCEDURE DevolverLivro(IN p_id_usuario INT, IN p_id_livro INT, IN p_data_devolucao DATE)
BEGIN
    DECLARE v_data_prazo DATE;
    DECLARE v_penalizacao DATE;
    DECLARE v_id_reserva INT;
    DECLARE v_id_usuario_reserva INT;

    -- Verificar se o usuário tem o livro emprestado e se ainda não foi devolvido
    IF (SELECT COUNT(*) FROM emprestimos WHERE id_usuario = p_id_usuario AND id_livro = p_id_livro AND devolvido = FALSE) = 1 THEN
        -- Obter a data de prazo de devolução para verificar atrasos
        SELECT data_devolucao INTO v_data_prazo FROM emprestimos WHERE id_usuario = p_id_usuario AND id_livro = p_id_livro AND devolvido = FALSE;

        -- Atualizar na tabela emprestimos a data de devolução e marcar como devolvido
        UPDATE emprestimos SET data_devolucao = p_data_devolucao, devolvido = TRUE WHERE id_usuario = p_id_usuario AND id_livro = p_id_livro AND devolvido = FALSE;

        -- Verificar se a devolução está atrasada e aplicar penalidade
        IF p_data_devolucao > v_data_prazo THEN
            SET v_penalizacao = CASE 
                WHEN p_data_devolucao <= DATE_ADD(v_data_prazo, INTERVAL 15 DAY) THEN DATE_ADD(CURDATE(), INTERVAL 1 MONTH)
                WHEN p_data_devolucao <= DATE_ADD(v_data_prazo, INTERVAL 1 MONTH) THEN DATE_ADD(CURDATE(), INTERVAL 3 MONTH)
                WHEN p_data_devolucao <= DATE_ADD(v_data_prazo, INTERVAL 3 MONTH) THEN DATE_ADD(CURDATE(), INTERVAL 6 MONTH)
                WHEN p_data_devolucao <= DATE_ADD(v_data_prazo, INTERVAL 6 MONTH) THEN DATE_ADD(CURDATE(), INTERVAL 1 YEAR)
                WHEN p_data_devolucao <= DATE_ADD(v_data_prazo, INTERVAL 12 MONTH) THEN DATE_ADD(CURDATE(), INTERVAL 2 YEAR)
                ELSE '9999-12-31' -- Interdição permanente
            END;

            -- Atualizar a penalização do usuário
            UPDATE users SET penalizado_ate = v_penalizacao WHERE id = p_id_usuario;
        END IF;

        -- Atualizar estado do livro para disponível
        UPDATE livros SET disponibilidade = TRUE WHERE id = p_id_livro;

        -- Atualizar número de livros emprestados do usuário
        UPDATE users SET num_livros_emprestados = num_livros_emprestados - 1 WHERE id = p_id_usuario;
        
        -- Verificar se há reservas pendentes para o livro de outros usuários
        IF (SELECT COUNT(*) FROM reservations WHERE id_livro = p_id_livro AND status = 'pendente') > 0 THEN
            -- Obter o próximo id da reserva pendente
            SELECT id INTO v_id_reserva FROM reservations WHERE id_livro = p_id_livro AND status = 'pendente' LIMIT 1;

            -- Aprovar a próxima reserva pendente de outro usuário
            UPDATE reservations SET status = 'aprovada' WHERE id = v_id_reserva;

            -- Obter o próximo usuário com a reserva aprovada
            SELECT id_usuario INTO v_id_usuario_reserva FROM reservations WHERE id = v_id_reserva;
            
            -- Chamar o procedimento EmprestarLivro para o próximo usuário
            CALL EmprestarLivro(v_id_usuario_reserva, p_id_livro);
        END IF;

    ELSE
        -- Se o usuário não tem esse livro emprestado ou já foi devolvido
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro: O usuário não tem este livro emprestado ou já foi devolvido';
    END IF;
END $$
DELIMITER ;
# drop procedure DevolverLivro;

DELIMITER $$
CREATE PROCEDURE ExecutarChamadas()							-- Para evitar que nao execute CALLS seguintes a erros textuais que quis destacar
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLWARNING
    BEGIN
        -- Lógica para lidar com avisos e erros (pode ser personalizada conforme necessário)
        -- Exemplo: apenas ignorar e continuar
    END;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Lógica para lidar com exceções SQL
        -- Exemplo: Ignorar exceções e continuar com o próximo comando
    END;

    -- Executar as chamadas
    CALL EmprestarLivro(1,4);
    CALL EmprestarLivro(2,5);
    CALL DevolverLivro(1,4,'2025-11-18');
    CALL DevolverLivro(2,5,'2024-10-25');
    CALL EmprestarLivro(3,5);
    CALL EmprestarLivro(4,5);
    CALL DevolverLivro(3,5,'2024-11-17');
    CALL EmprestarLivro(1,4);
    CALL EmprestarLivro(3,4);
    CALL DevolverLivro(3,4,'2024-10-10');
    CALL EmprestarLivro(5,2);
    CALL DevolverLivro(5,2,'2024-09-25');
    CALL EmprestarLivro(5,9);
    CALL DevolverLivro(5,9,'2025-11-17');
    CALL EmprestarLivro(7,14);
    CALL DevolverLivro(7,14,'2025-10-20');
    CALL EmprestarLivro(3,13);
    CALL DevolverLivro(3,13,'2024-11-11');
END $$
DELIMITER ;
# drop procedure ExecutarChamadas;

CALL ExecutarChamadas();