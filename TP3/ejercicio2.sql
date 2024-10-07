SELECT *
FROM voluntario;

SELECT *
FROM tarea;

SELECT *
FROM historico
ORDER BY nro_voluntario;

--CREATE TABLE IF NOT EXISTS TAREA AS
--    SELECT * FROM unc_esq_voluntario.tarea;

--CREATE TABLE IF NOT EXISTS HISTORICO AS
--    SELECT * FROM unc_esq_voluntario.historico;

SELECT v.nro_voluntario, v.horas_aportadas, v.id_tarea, v.id_coordinador, c.horas_aportadas, c.id_tarea
FROM voluntario v JOIN voluntario c ON (v.id_coordinador = c.nro_voluntario);

-- 2 (4a)
CREATE OR REPLACE FUNCTION FN_VOL_HS_COORD()
RETURNS TRIGGER AS $$
DECLARE
	horas_aportadas_coord INTEGER;
BEGIN
	SELECT c.horas_aportadas
	INTO horas_aportadas_coord
	FROM voluntario c
	WHERE c.nro_voluntario = NEW.id_coordinador;
	IF (NEW.horas_aportadas > horas_aportadas_coord) THEN
		RAISE EXCEPTION 'El voluntario no puede aportar mas horas que las de su coordinador';
	END IF;
	RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER TR_VOL_HS_COORD
BEFORE INSERT OR UPDATE OF horas_aportadas
ON VOLUNTARIO
FOR EACH ROW
EXECUTE FUNCTION FN_VOL_HS_COORD();

ALTER TABLE voluntario DISABLE TRIGGER TR_VOL_HS_COORD;

-- id_tarea = SA_REP, max horas: 12000
-- modifico horas del coordinador nro: 147 ,horas originales: 12000
UPDATE voluntario
SET horas_aportadas = 11000
WHERE nro_voluntario = 147;

-- falla, porque 11500 horas son mayores que las de su coordinador (nro: 147) que son: 11000
UPDATE voluntario
SET horas_aportadas = 11500
WHERE nro_voluntario = 162; -- 10500 horas originales

-- arreglo las horas del coordinador nro: 147
UPDATE voluntario
SET horas_aportadas = 12000
WHERE nro_voluntario = 147;

-- 2 (4b)
CREATE OR REPLACE FUNCTION FN_VOL_HS_TAREA()
RETURNS TRIGGER AS $$
DECLARE min_horas INTEGER;
    max_horas INTEGER;
BEGIN
	SELECT t.min_horas, t.max_horas
	INTO min_horas, max_horas
	FROM tarea t
	WHERE t.id_tarea = NEW.id_tarea;
	IF (new.horas_aportadas != 0) and (NEW.horas_aportadas < min_horas or NEW.horas_aportadas> max_horas) THEN  -- Si las horas no son cero, verifico si están dentro del rango (lo del cero es para permitir que las horas_aportadas sean cero en ejercicio 6a)
		RAISE EXCEPTION 'Las horas aportadas del voluntario está por fuera de los valores maximos y minimos consignados en su tarea.';
	END IF;
	RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER TR_VOL_HS_TAREA
BEFORE INSERT OR UPDATE OF horas_aportadas
ON VOLUNTARIO
FOR EACH ROW
EXECUTE FUNCTION FN_VOL_HS_TAREA();

--se bloquea esta actualización porque 6000 horas exceden el límite para la tarea 'ST_CLERK' (5000).
UPDATE voluntario
SET horas_aportadas = 6000
WHERE nro_voluntario = 136;

-- Actualización válida: Horas dentro del límite (Por ejemplo, cambiar a 2900 horas)
UPDATE voluntario
SET horas_aportadas = 2900
WHERE nro_voluntario = 136;

-- tambien acepta cambiar a 5000 horas, justo el maximo
UPDATE voluntario
SET horas_aportadas = 5000
WHERE nro_voluntario = 136;

-- cambio a 2200 horas, el original
UPDATE voluntario
SET horas_aportadas = 2200
WHERE nro_voluntario = 136;

--SELECT tgname FROM pg_trigger WHERE tgrelid = 'voluntario'::regclass; -- para ver los nombres de los triggers que están asociados con la tabla.

--ALTER TABLE voluntario DISABLE TRIGGER TR_VOL_HS_COORD;

-- 3 (4c. “Todos los voluntarios deben realizar la misma tarea que su coordinador”)

CREATE OR REPLACE FUNCTION FN_VOL_TAREA_COORD()
RETURNS TRIGGER AS $$
BEGIN
	IF ( NEW.id_tarea <> (
		SELECT c.id_tarea
		FROM voluntario c
		WHERE c.nro_voluntario = NEW.id_coordinador)
	) THEN
		RAISE EXCEPTION 'El voluntario no puede realizar una tarea distinta a la de su coordinador.';
	END IF;
	RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER TR_VOL_TAREA_COORD
BEFORE INSERT OR UPDATE OF id_tarea
ON VOLUNTARIO
FOR EACH ROW
EXECUTE FUNCTION FN_VOL_TAREA_COORD();

-- falla porque el coordinador (nro: 122) tiene tarea ST_MAN, por mas q ya haga una tarea distinta
UPDATE voluntario
SET id_tarea = 'AD_PRES'
WHERE nro_voluntario = 134

-- 4 (4d “Los voluntarios no pueden cambiar de institución más de tres veces en un año.”)

CREATE OR REPLACE FUNCTION FN_VOL_CANT_INST()
RETURNS TRIGGER AS $$
DECLARE
	cont INTEGER;
BEGIN
	SELECT count(*)
	INTO cont
	FROM historico h
	WHERE h.nro_voluntario = NEW.nro_voluntario and EXTRACT(YEAR FROM h.fecha_inicio) = EXTRACT(YEAR FROM NEW.fecha_inicio);
	IF (cont >= 3) THEN  -- Verificar si el número de cambios es mayor que 3 en el mismo año
		RAISE EXCEPTION 'El voluntario no puede cambiar de institucion mas de tres veces en un año';
	END IF;
	RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER TR_VOL_CANT_INST_historico
BEFORE INSERT OR UPDATE OF id_institucion
ON historico
FOR EACH ROW
EXECUTE FUNCTION FN_VOL_CANT_INST();
-- debe fallar porque ya hay varios cambios en 2021
INSERT INTO historico
VALUES ('2021-01-01', 100, '2021-09-28', 'HR_REP', 80);

DELETE FROM historico
WHERE fecha_inicio = '2021-01-01' and nro_voluntario = 100;

-- DROP TRIGGER IF EXISTS TR_VOL_CANT_INST ON voluntario;