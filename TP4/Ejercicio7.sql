CREATE VIEW vista1 AS
    SELECT nro_voluntario, nombre, apellido, horas_aportadas, t.*
    FROM voluntario v JOIN tarea t USING(id_tarea);

