CREATE TABLE IF NOT EXISTS institucion AS
    SELECT * FROM unc_esq_voluntario.institucion;

CREATE TABLE IF NOT EXISTS direccion AS
    SELECT * FROM unc_esq_voluntario.direccion;

CREATE VIEW vista1_vol AS
    SELECT nro_voluntario, nombre, apellido, horas_aportadas, t.*
    FROM voluntario v JOIN tarea t USING(id_tarea);

CREATE OR REPLACE FUNCTION fn_insert_vol_tarea()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO voluntario (nombre, apellido, e_mail, telefono, fecha_nacimiento, id_tarea, nro_voluntario, horas_aportadas, porcentaje, id_institucion, id_coordinador)
    VALUES (NEW.nombre, NEW.apellido, new.e_mail, new.telefono,  new.fecha_nacimiento, NEW.id_tarea, NEW.nro_voluntario, NEW.horas_aportadas, NEW.porcentaje, NEW.id_institucion, NEW.id_coordinador);

    RETURN NEW;
    end;
$$ language plpgsql;

CREATE TRIGGER tr_datos_vol_tarea
INSTEAD OF INSERT ON vista1_vol
FOR EACH ROW EXECUTE FUNCTION fn_insert_vol_tarea();

CREATE OR REPLACE FUNCTION fn_actualizar_vol_tarea()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE voluntario
    SET nombre = new.nombre,
        apellido = new.apellido,
        e_mail = new.e_mail,
        telefono = new.telefono,
        fecha_nacimiento = new.fecha_nacimiento,
        id_tarea = new.id_tarea,
        nro_voluntario = new.nro_voluntario,
        horas_aportadas = new.horas_aportadas,
        porcentaje = new.porcentaje,
        id_institucion = new.id_institucion,
        id_coordinador = new.id_coordinador
    WHERE nro_voluntario = OLD.nro_voluntario;

    RETURN new;
end;
$$ language plpgsql;

CREATE TRIGGER tr_actualizar_vol_tarea
INSTEAD OF UPDATE ON vista1_vol
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_vol_tarea();

CREATE OR REPLACE FUNCTION fn_delete_vol_tarea()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM voluntario
    WHERE nro_voluntario = old.nro_voluntario;

    DELETE FROM institucion
    WHERE id_institucion = old.id_institucion; -- falta alguna clave?

    RETURN old;
    end;
$$ language plpgsql;

CREATE TRIGGER tr_delete_vol_tarea
INSTEAD OF DELETE ON vista1_vol
FOR EACH ROW EXECUTE FUNCTION fn_delete_vol_tarea();

CREATE VIEW vista2_vol AS
SELECT i.id_institucion, i.nombre_institucion,
       (SELECT COUNT(DISTINCT v.id_tarea)
        FROM voluntario v
        WHERE v.id_institucion = i.id_institucion) AS total_tareas_realizadas
FROM institucion i
WHERE i.id_direccion IN(
    SELECT d.id_direccion
    FROM direccion d
    );

CREATE VIEW vista2_vol AS
    SELECT i.*, COUNT(distinct v.id_tarea) AS Cant_tareas_realizadas
    FROM institucion i JOIN voluntario v ON (i.id_institucion = v.id_institucion)
        JOIN direccion d ON (i.id_direccion = d.id_direccion)
        WHERE d.id_pais = 'US'
    GROUP BY i.id_institucion, i.nombre_institucion, i.id_director, i.id_direccion;

CREATE OR REPLACE FUNCTION fn_insert_vista2()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO institucion(id_institucion, nombre_institucion, id_director, id_director)
    VALUES (NEW.id_institucion, NEW.nombre_institucion, NEW.id_director, NEW.id_director);

    RETURN NEW;
end;
$$ language plpgsql;

CREATE TRIGGER tr_insert_vista2
INSTEAD OF INSERT on vista2_vol
FOR EACH ROW EXECUTE FUNCTION fn_insert_vista2();

CREATE OR REPLACE FUNCTION fn_actualizar_vista2()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE institucion
    SET id_institucion = NEW.id_institucion,
        nombre_institucion = NEW.nombre_institucion,
        id_director = NEW.id_director,
        id_direccion = NEW.id_direccion
    WHERE id_institucion = OLD.id_institucion;

    RETURN NEW;
end;
$$ language plpgsql;

CREATE TRIGGER tr_actualizar_vista2
INSTEAD OF UPDATE on vista2_vol
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_vista2();

CREATE OR REPLACE FUNCTION fn_eliminar_vista2()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM institucion
    WHERE id_institucion = OLD.id_institucion;

    RETURN OLD;
end;
$$ language plpgsql;

CREATE TRIGGER tr_eliminar_vista2
INSTEAD OF DELETE on vista2_vol
FOR EACH ROW EXECUTE FUNCTION fn_eliminar_vista2();

CREATE VIEW vista3_vol AS
    SELECT i.id_institucion, i.nombre_institucion, COUNT(*) as cant_voluntarios
    FROM voluntario JOIN institucion i USING (id_institucion)
    GROUP BY i.id_institucion, i.nombre_institucion;

CREATE OR REPLACE FUNCTION fn_insertar_vista3()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO institucion(id_institucion, nombre_institucion, id_director, id_direccion)
    VALUES (NEW.id_institucion, NEW.nombre_institucion, NEW.id_director, NEW.id_direccion);

    RETURN NEW;
end;
$$ language plpgsql;

CREATE TRIGGER tr_insertar_vista3
INSTEAD OF INSERT on vista3_vol
FOR EACH ROW EXECUTE FUNCTION fn_insertar_vista3();

CREATE OR REPLACE FUNCTION fn_actualizar_vista3()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE institucion
    SET id_institucion = NEW.id_institucion,
        nombre_institucion = NEW.nombre_institucion,
        id_director = NEW.id_director,
        id_direccion = NEW.id_direccion
    WHERE id_institucion = OLD.id_institucion;

    RETURN NEW;
    end;
$$ language plpgsql;

CREATE TRIGGER tr_actualizar_vista3
INSTEAD OF INSERT on vista3_vol
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_vista3();

CREATE OR REPLACE FUNCTION fn_eliminar_vista3()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM institucion
    WHERE id_institucion = OLD.id_institucion;

    RETURN OLD;
end;
$$ language plpgsql;

CREATE TRIGGER tr_eliminar_vista3
INSTEAD OF INSERT on vista3_vol
FOR EACH ROW EXECUTE FUNCTION fn_eliminar_vista3();

SELECT *
FROM vista1_vol;

SELECT *
FROM vista2_vol;

SELECT *
FROM vista3_vol;