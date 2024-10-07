CREATE TABLE IF NOT EXISTS HIS_ENTREGA(
    nro_registro SERIAL NOT NULL,
    fecha TIMESTAMP NOT NULL,
    operacion varchar(10) NOT NULL,
    cant_reg_afectados int NOT NULL,
    usuario varchar(30) NOT NULL
);

ALTER TABLE HIS_ENTREGA ADD CONSTRAINT pk_HIS_ENTREGA PRIMARY KEY (nro_registro);

CREATE TABLE IF NOT EXISTS renglon_entrega AS
    SELECT * FROM unc_esq_peliculas.renglon_entrega;

CREATE TABLE IF NOT EXISTS entrega AS
    SELECT * FROM unc_esq_peliculas.entrega;

-----------------------------------------------------------------------
CREATE TABLE AUXILIAR_CONTADOR (
    id_usuario varchar(30),
    contador int
);


CREATE OR REPLACE FUNCTION FN_CONTAR_FILAS_AFECTADAS()
RETURNS TRIGGER AS $$
BEGIN
    -- Si ya existe un contador para el usuario actual, se incrementa
    IF EXISTS (SELECT 1 FROM AUXILIAR_CONTADOR WHERE id_usuario = session_user) THEN
        UPDATE AUXILIAR_CONTADOR
        SET contador = contador + 1
        WHERE id_usuario = session_user;
    ELSE
    -- Si no existe, se inserta un nuevo contador
        INSERT INTO AUXILIAR_CONTADOR (id_usuario, contador)
        VALUES (session_user, 1);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Creación de triggers 'FOR EACH ROW' para las tablas ENTREGA y RENGLON_ENTREGA
CREATE TRIGGER TR_COUNT_ROW_RENGLON_ENTREGA
AFTER INSERT OR UPDATE OR DELETE
ON renglon_entrega
FOR EACH ROW
EXECUTE FUNCTION FN_CONTAR_FILAS_AFECTADAS();

CREATE TRIGGER TR_COUNT_ROW_ENTREGA
AFTER INSERT OR UPDATE OR DELETE
ON entrega
FOR EACH ROW
EXECUTE FUNCTION FN_CONTAR_FILAS_AFECTADAS();

CREATE OR REPLACE FUNCTION FN_INSERTAR_HIS_ENTREGA()
RETURNS TRIGGER AS $$
DECLARE
    filas_afectadas INT;
BEGIN
    -- Obtener la cantidad de registros afectados para el usuario actual
    SELECT contador INTO filas_afectadas FROM AUXILIAR_CONTADOR WHERE id_usuario = session_user;

    -- Insertar los detalles en la tabla HIS_ENTREGA
    INSERT INTO HIS_ENTREGA (fecha, operacion, cant_reg_afectados, usuario)
    VALUES (current_timestamp, TG_OP, filas_afectadas, session_user);

    -- Reiniciar el contador del usuario actual
    DELETE FROM AUXILIAR_CONTADOR WHERE id_usuario = session_user;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Creación de triggers 'FOR EACH STATEMENT' para las tablas ENTREGA y RENGLON_ENTREGA
CREATE TRIGGER TR_INSERT_HIS_RENGLON_ENTREGA
AFTER INSERT OR UPDATE OR DELETE
ON renglon_entrega
FOR EACH STATEMENT
EXECUTE FUNCTION FN_INSERTAR_HIS_ENTREGA();

CREATE TRIGGER TR_INSERT_HIS_ENTREGA
AFTER INSERT OR UPDATE OR DELETE
ON entrega
FOR EACH STATEMENT
EXECUTE FUNCTION FN_INSERTAR_HIS_ENTREGA();
-----------------------------------------------------------------------

--si realizo alguna modificacion en los trigger, hacer drop del trigger y despues agregarlo otra vez

DROP TRIGGER TR_ACT_HIS_RENGLON_ENTREGA ON renglon_entrega;
DROP TRIGGER TR_ACT_HIS_ENTREGA ON entrega;

SELECT * FROM HIS_ENTREGA;

-- borra todooo DELETE FROM HIS_ENTREGA;


-- b)

SELECT *
FROM entrega
WHERE id_video = 3582;

UPDATE entrega
set fecha_entrega = '2010-05-14'
WHERE id_video = 3582

DELETE FROM entrega WHERE id_video = 3582;

INSERT INTO entrega VALUES (389,'2010-04-22',3582,735);
INSERT INTO entrega VALUES (3890,'2005-04-03',3582,484);
INSERT INTO entrega VALUES (4268,'2010-01-15',3582,735);
