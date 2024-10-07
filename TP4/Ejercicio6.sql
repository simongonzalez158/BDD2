CREATE VIEW ciudad_kp_2 AS
SELECT id_ciudad, nombre_ciudad, c.id_pais, nombre_pais
FROM unc_esq_peliculas.ciudad c NATURAL JOIN unc_esq_peliculas.pais p;

CREATE VIEW entregas_kp_3 AS
SELECT nro_entrega, re.codigo_pelicula, cantidad, titulo
FROM renglon_entrega re JOIN unc_esq_peliculas.pelicula p using (codigo_pelicula);

CREATE TABLE IF NOT EXISTS ciudad AS
    SELECT * FROM unc_esq_peliculas.ciudad;

CREATE TABLE IF NOT EXISTS pais AS
    SELECT * FROM unc_esq_peliculas.pais;

CREATE OR REPLACE FUNCTION fn_actualizar_ciudad_kp_2()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ciudad
    SET nombre_ciudad = NEW.nombre_ciudad
    WHERE id_ciudad = OLD.id_ciudad;

    UPDATE pais
    SET nombre_pais = NEW.nombre_pais
    WHERE id_pais = OLD.nombre_pais;

    RETURN NEW;
end;
$$ language 'plpglsql';

CREATE TRIGGER tr_actualizar_ciudad_kp_2
INSTEAD OF UPDATE ON ciudad_kp_2
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_ciudad_kp_2();

CREATE OR REPLACE FUNCTION fn_insertar_ciudad_kp_2()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO ciudad (id_ciudad, nombre_ciudad, id_pais)
    VALUES (NEW.id_ciudad, NEW.nombre_ciudad, NEW.id_pais);

    INSERT INTO pais (id_pais, nombre_pais)
    VALUES (NEW.id_pais, NEW.nombre_pais);

    RETURN NEW;
end;
$$ language 'plpglsql';

CREATE TRIGGER tr_insertar_ciudad_kp_2
INSTEAD OF INSERT ON ciudad_kp_2
FOR EACH ROW EXECUTE FUNCTION fn_insertar_ciudad_kp_2();

