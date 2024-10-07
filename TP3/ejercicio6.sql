-- a)

CREATE OR REPLACE FUNCTION fn_horas_cero()
RETURNS TRIGGER AS $$
begin
    UPDATE voluntario
    SET horas_aportadas = 0
    WHERE nro_voluntario = new.nro_voluntario;
    RETURN new;
end;
$$ language 'plpgsql';

CREATE TRIGGER TR_ACT_VOLUNTARIO
    AFTER UPDATE of id_tarea ON voluntario
    FOR EACH ROW
    EXECUTE FUNCTION fn_horas_cero();

CREATE OR REPLACE FUNCTION fn_horas_cero_before()
RETURNS TRIGGER AS $$
begin
    NEW.horas_aportadas = 0;
    RETURN NEW;
end;
$$ language 'plpgsql';

CREATE TRIGGER TR_ACT_VOLUNTARIO_BEFORE
    BEFORE UPDATE of id_tarea ON voluntario
    FOR EACH ROW
    EXECUTE FUNCTION fn_horas_cero_before();

DROP TRIGGER TR_ACT_VOLUNTARIO ON voluntario;
DROP TRIGGER TR_ACT_VOLUNTARIO_BEFORE ON voluntario;

SELECT *
FROM voluntario
WHERE nro_voluntario = 100;

SELECT *
FROM tarea
WHERE id_tarea = 'AD_VP';

-- cambio tarea del voluntario 100 a AD_VP (su antigua era AD_PRES)
UPDATE voluntario
    SET id_tarea = 'AD_VP'
    WHERE nro_voluntario = 100;

-- me fijo que las horas aportadas del voluntario sean cero
SELECT *
FROM voluntario
WHERE nro_voluntario = 100;

-- vuelvo tabla a estado original
UPDATE voluntario
set id_tarea = 'AD_PRES'
WHERE nro_voluntario = 100;

UPDATE voluntario
set horas_aportadas = 24000 -- las horas originales eran 24000
WHERE nro_voluntario = 100;

-- b

CREATE OR REPLACE FUNCTION fn_horas_porcentaje()
RETURNS TRIGGER AS $$
begin
    IF (new.horas_aportadas < old.horas_aportadas*0.9 or new.horas_aportadas > old.horas_aportadas*1.1)
        -- otra forma (new.horas_aportadas NOT BETWEEN OLD.horas_aportadas*0.9 and OLD.horas_aportadas*1.1)
        THEN RAISE EXCEPTION 'la nueva cantidad de horas aportadas no puede ser menor ni mayor al 10%% de la cantidad anterior';
    END IF;
    RETURN NEW;
end;
$$ language 'plpgsql';

CREATE TRIGGER TR_HORAS_PORCENTAJE
    BEFORE UPDATE OF horas_aportadas ON voluntario
    FOR EACH ROW
    EXECUTE FUNCTION fn_horas_porcentaje();

DROP TRIGGER TR_HORAS_PORCENTAJE ON voluntario;

-- no deberia dejar porque las horas aportadas originales (24000)*0.9 = 21600
UPDATE voluntario
set horas_aportadas = 21000
WHERE nro_voluntario = 100;

-- no deberia dejar porque las horas aportadas originales (24000)*0.1 = 26400
UPDATE voluntario
set horas_aportadas = 27000
WHERE nro_voluntario = 100;

-- lo permite porque esta dentro del rango
UPDATE voluntario
set horas_aportadas = 24500
WHERE nro_voluntario = 100;

UPDATE voluntario
set horas_aportadas = 24000 -- las horas originales eran 24000
WHERE nro_voluntario = 100;