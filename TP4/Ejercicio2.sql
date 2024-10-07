CREATE VIEW EMPLEADO_DIST_20 AS
    SELECT e.id_empleado, e.nombre, e.apellido, e.sueldo, e.fecha_nacimiento
    FROM unc_esq_peliculas.empleado e
    WHERE d.id_distribuidor = 20;

SELECT *
FROM EMPLEADO_DIST_20;

CREATE VIEW EMPLEADO_DIST_2000 AS
    SELECT e.id_empleado, e.nombre, e.apellido, e.sueldo
    FROM EMPLEADO_DIST_20 e
    WHERE e.sueldo > 2000;

SELECT *
FROM EMPLEADO_DIST_2000;

CREATE VIEW EMPLEADO_DIST_20_70 AS
    SELECT *
    FROM EMPLEADO_DIST_20
    WHERE extract(year from (fecha_nacimiento)) BETWEEN 1970 and 1979;

SELECT *
FROM EMPLEADO_DIST_20_70;

CREATE VIEW PELICULAS_ENTREGADAS AS
    SELECT r.codigo_pelicula, r.cantidad
    FROM unc_esq_peliculas.renglon_entrega r;

SELECT *
FROM PELICULAS_ENTREGADAS;

CREATE VIEW DISTRIB_NAC AS
    SELECT n.id_distribuidor, n.nro_inscripcion, n.encargado
    FROM unc_esq_peliculas.nacional n JOIN unc_esq_peliculas.internacional i USING(id_distribuidor)
    WHERE i.codigo_pais = 'AR';

SELECT *
FROM DISTRIB_NAC;

CREATE VIEW DISTRIB_NAC_MAS2EMP AS
    SELECT n.id_distribuidor, n.nro_inscripcion, n.encargado
    FROM DISTRIB_NAC n
    JOIN unc_esq_peliculas.departamento d ON (n.id_distribuidor = d.id_distribuidor)
    JOIN empleado e ON d.id_departamento=e.id_departamento and d.id_distribuidor = e.id_distribuidor
    GROUP BY n.id_distribuidor, n.nro_inscripcion, n.encargado
    HAVING COUNT(e.id_empleado) > 2;

DROP VIEW DISTRIB_NAC_MAS2EMP;

CREATE VIEW DISTRIB_NAC_MAS2EMP AS
    SELECT n.id_distribuidor, n.nro_inscripcion, n.encargado
    FROM DISTRIB_NAC n
    WHERE n.id_distribuidor IN(
        SELECT d.id_distribuidor
        FROM unc_esq_peliculas.departamento d
        WHERE (d.id_departamento, d.id_distribuidor) IN(
            SELECT e.id_departamento, e.id_distribuidor
            FROM unc_esq_peliculas.empleado e
            GROUP BY e.id_departamento, e.id_distribuidor
            HAVING COUNT(e.id_empleado) > 2
        )
    );
