CREATE TABLE IF NOT EXISTS empleado AS
SELECT * from unc_esq_peliculas.empleado;

ALTER TABLE empleado
ADD CONSTRAINT pk_empleado PRIMARY KEY (id_empleado);

CREATE TABLE IF NOT EXISTS INFO_HISTORICA (
    id_empleado numeric(6,0) NOT NULL,
    fecha_inicio date,
    fecha_fin date,
    id_distribuidor numeric(5,0),
    id_departamento numeric(4,0),
    CONSTRAINT pk_info_historica PRIMARY KEY (id_empleado, fecha_inicio, id_distribuidor, id_departamento)
);

ALTER TABLE INFO_HISTORICA
ADD CONSTRAINT fk_info_historica_empleado
    FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado);

CREATE OR REPLACE FUNCTION fn_agregar_empleado() -- se agrega el nuevo empleado a la tabla INFO_HISTORICA
RETURNS TRIGGER AS $$
BEGIN
    insert into INFO_HISTORICA (id_empleado, fecha_inicio, id_distribuidor, id_departamento) values (new.id_empleado, current_date, new.id_distribuidor, new.id_departamento);
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER TR_AGREGA_EMPLEADO
    AFTER insert ON empleado
    for each row
    execute function fn_agregar_empleado();

CREATE OR REPLACE FUNCTION fn_modificar_empleado() -- cuando se cambia el departamento y distribuidor (id_depto y id_distrib), agrego la fecha de fin en INFO_HISTORICA para el empleado en esos departamentos, y se crea un nuevo registro para ese empleado con el nuevo depto y distrib
RETURNS TRIGGER AS $$
BEGIN
    UPDATE INFO_HISTORICA
    SET fecha_fin = current_date
    WHERE (id_empleado = old.id_empleado) and (id_distribuidor = old.id_distribuidor) and (id_departamento = old.id_departamento) and (fecha_fin is null);
    insert into INFO_HISTORICA (id_empleado, fecha_inicio, id_distribuidor, id_departamento) values (new.id_empleado, current_date, new.id_distribuidor, new.id_departamento);
    RETURN NEW;
end;
$$ language 'plpgsql';

CREATE TRIGGER TR_MOD_EMPLEADO
    AFTER UPDATE of id_departamento, id_distribuidor
    ON empleado
    FOR EACH ROW
    EXECUTE FUNCTION fn_modificar_empleado();

CREATE OR REPLACE FUNCTION fn_eliminar_empleado() -- elimina de info_empleado el empleado al q se hae delete
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM INFO_HISTORICA
        WHERE (id_empleado = old.id_empleado);
    RETURN NEW;
end;
$$ language 'plpgsql';

CREATE TRIGGER TR_ELIM_EMPLEADO
    BEFORE DELETE ON empleado
    FOR EACH ROW
    EXECUTE FUNCTION fn_eliminar_empleado();

SELECT *
FROM INFO_HISTORICA;

SELECT *
FROM empleado
ORDER BY id_empleado desc;

SELECT *
    FROM tarea;

SELECT *
    FROM unc_esq_peliculas.departamento;

INSERT INTO empleado (id_empleado, nombre, apellido, e_mail, fecha_nacimiento, id_tarea, id_departamento, id_distribuidor) values (35082, 'a', 'b', 'email@gmail.com',  '05/02/1999', 'AD_VP', 75, 219);

UPDATE empleado
SET id_tarea = 'otra tarea'
WHERE id_empleado = 35082;

UPDATE empleado
SET id_departamento = 52, id_distribuidor = 445
WHERE id_empleado = 35082;

DELETE FROM empleado
WHERE id_empleado = 35082;