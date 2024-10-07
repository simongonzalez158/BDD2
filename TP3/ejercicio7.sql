CREATE TABLE IF NOT EXISTS ARTICULO (
    id_articulo int NOT NULL,
    titulo varchar(100) NOT NULL,
    autor varchar(50) NOT NULL,
    nacionalidad varchar(50) NOT NULL,
    fecha_pub date,
    CONSTRAINT pk_articulo primary key (id_articulo)
);

CREATE TABLE IF NOT EXISTS TextosPorAutor (
    autor varchar(50),
    cant_textos int NOT NULL,
    fecha_ultima_publicacion date,
    CONSTRAINT pk_TextosPorAutor primary key (autor)
);

-- a)

CREATE OR REPLACE FUNCTION fn_act_textos_por_autor()
RETURNS void AS $$
begin
    DELETE FROM TextosPorAutor;

    INSERT INTO TextosPorAutor (autor, cant_textos, fecha_ultima_publicacion)
    SELECT autor, count(*) AS cant_textos, MAX(fecha_pub) AS fecha_ultima_publicacion
    FROM ARTICULO
    GROUP BY autor;
end;
$$ language 'plpgsql';

INSERT INTO articulo VALUES (1,	'Texto 1',	'Autor A',	'País A',	'2022-01-10');
INSERT INTO articulo VALUES (2,	'Texto 2',	'Autor A',	'País A',	'2022-05-14');
INSERT INTO articulo VALUES (3	,'Texto 3'	,'Autor B'	,'País B'	,'2023-02-25');

SELECT fn_act_textos_por_autor();

SELECT *
FROM TextosPorAutor;

-- b)

CREATE OR REPLACE FUNCTION fn_act_textosporautor_insert()
RETURNS TRIGGER AS $$
begin
    perform fn_act_textos_por_autor();
    RETURN NEW;
end;
$$ language 'plpgsql';

CREATE TRIGGER tr_act_articulo_insert
    AFTER INSERT ON ARTICULO
    FOR EACH ROW
    EXECUTE FUNCTION fn_act_textosporautor_insert();

CREATE OR REPLACE FUNCTION fn_act_textosporautor_act()
RETURNS TRIGGER AS $$
begin
    UPDATE TextosPorAutor
    SET fecha_ultima_publicacion = new.fecha_pub
    WHERE autor = new.autor and fecha_ultima_publicacion is null;
end;
$$ language 'plpgsql';

CREATE TRIGGER tr_act_articulo_act
    AFTER update of fecha_pub ON ARTICULO
    FOR EACH ROW
    EXECUTE FUNCTION fn_act_textosporautor_act();

CREATE OR REPLACE FUNCTION fn_act_textosporautor_delete()
RETURNS TRIGGER AS $$
begin
    DELETE FROM TextosPorAutor
    WHERE autor = new.autor;
    RETURN NEW;
end;
$$ language 'plpgsql';

CREATE TRIGGER tr_act_articulo_delete
    AFTER DELETE ON ARTICULO
    FOR EACH ROW
    EXECUTE FUNCTION fn_act_textosporautor_delete();

INSERT INTO articulo (id_articulo, titulo, autor, nacionalidad, fecha_pub)
VALUES (4, 'Nuevo Artículo', 'Autor C', 'País C', '2023-09-28');

DELETE FROM articulo WHERE id_articulo = 4;

SELECT * FROM ARTICULO;

UPDATE ARTICULO
SET fecha_pub = null
WHERE id_articulo = 4;

DELETE FROM ARTICULO
WHERE id_articulo = 4;