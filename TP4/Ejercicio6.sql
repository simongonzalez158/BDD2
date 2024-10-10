CREATE VIEW ciudad_kp_2 AS
SELECT c.id_ciudad, c.nombre_ciudad, c.id_pais, p.nombre_pais
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
$$ language 'plpgsql';

CREATE TRIGGER tr_insertar_ciudad_kp_2
INSTEAD OF INSERT ON ciudad_kp_2
FOR EACH ROW EXECUTE FUNCTION fn_insertar_ciudad_kp_2();

-- -- -- -- -- -- --
-- a

CREATE OR REPLACE FUNCTION fn_update_ciudad() -- PREGUNTAR
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ciudad
    SET id_ciudad = new.id_ciudad,
        nombre_ciudad = new.nombre_ciudad,
        id_pais= new.id_pais
        --nombre_ciudad = NEW.nombre_ciudad
    WHERE id_ciudad = OLD.id_ciudad;

    RETURN NEW;
end;
$$ language plpgsql;

CREATE TRIGGER tr_update_ciudad
INSTEAD OF UPDATE ON ciudad_kp_2
FOR EACH ROW EXECUTE FUNCTION fn_update_ciudad();

CREATE OR REPLACE FUNCTION fn_delete_ciudad()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM ciudad
    WHERE id_ciudad = OLD.id_ciudad;

    RETURN OLD;
end;
$$ language plpgsql;

CREATE TRIGGER tr_delete_ciudad
INSTEAD OF DELETE ON ciudad_kp_2
FOR EACH ROW EXECUTE FUNCTION fn_delete_ciudad();

CREATE OR REPLACE FUNCTION fn_insert_ciudad()
RETURNS TRIGGER AS $$
BEGIN
    insert into ciudad(id_ciudad, nombre_ciudad, id_pais)
    VALUES (new.id_ciudad, new.nombre_ciudad, new.id_pais);

    RETURN new;
    end;
$$ language plpgsql;

CREATE TRIGGER tr_insert_ciudad
INSTEAD OF INSERT ON ciudad_kp_2
FOR EACH ROW EXECUTE FUNCTION fn_insert_ciudad();

-- b
CREATE OR REPLACE FUNCTION fn_actualizar_entrega()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE renglon_entrega
    SET cantidad = NEW.cantidad,
        nro_entrega = NEW.nro_entrega,
        codigo_pelicula = NEW.codigo_pelicula
    WHERE nro_entrega = old.nro_entrega and codigo_pelicula = old.codigo_pelicula;

    RETURN NEW;
    end;
$$ language plpgsql;

CREATE TRIGGER tr_actualizar_ciudad
INSTEAD OF UPDATE ON entregas_kp_3
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_entrega();

CREATE OR REPLACE FUNCTION fn_insertar_entrega()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO renglon_entrega(nro_entrega, codigo_pelicula, cantidad)
    VALUES (new.NRO_ENTREGA, new.codigo_pelicula, new.cantidad);

    RETURN NEW;
end;
$$ language plpgsql;

CREATE TRIGGER tr_insertar_entrega
INSTEAD OF INSERT ON entregas_kp_3
FOR EACH ROW EXECUTE FUNCTION fn_insertar_entrega();

CREATE OR REPLACE FUNCTION fn_delete_entrega()
RETURNS TRIGGER AS $$
BEGIN
    delete from renglon_entrega
    WHERE nro_entrega = old.nro_entrega and codigo_pelicula = old.codigo_pelicula;

    RETURN OLD;
end;
$$ language plpgsql;

CREATE TRIGGER tr_delete_entrega
INSTEAD OF DELETE ON entregas_kp_3
FOR EACH ROW EXECUTE FUNCTION fn_delete_entrega();

SELECT *
FROM entregas_kp_3;