DROP VIEW EMPLEADO_DIST_20;
DROP VIEW EMPLEADO_DIST_2000;
DROP VIEW EMPLEADO_DIST_20_70;

SELECT *
FROM empleado;

CREATE VIEW EMPLEADO_DIST_20 AS
    SELECT e.id_empleado, e.nombre, e.apellido, e.sueldo, e.fecha_nacimiento
    FROM empleado e
    WHERE e.id_distribuidor = 20
    WITH cascaded CHECK OPTION;

SELECT *
FROM EMPLEADO_DIST_20;

CREATE VIEW EMPLEADO_DIST_2000 AS
    SELECT e.id_empleado, e.nombre, e.apellido, e.sueldo
    FROM EMPLEADO_DIST_20 e
    WHERE e.sueldo > 2000
    WITH CHECK OPTION;

UPDATE EMPLEADO_DIST_20 SET sueldo = 6698 WHERE id_empleado = 674; --6698

SELECT *
FROM EMPLEADO_DIST_2000;

CREATE VIEW EMPLEADO_DIST_20_70 AS
    SELECT *
    FROM EMPLEADO_DIST_20
    WHERE extract(year from (fecha_nacimiento)) BETWEEN 1970 and 1979;

SELECT *
FROM EMPLEADO_DIST_20_70;