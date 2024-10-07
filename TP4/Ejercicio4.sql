CREATE OR REPLACE VIEW tarea10000hs AS
SELECT *  FROM tarea
WHERE max_horas > 10000
WITH LOCAL CHECK OPTION;

CREATE OR REPLACE VIEW tarea10000rep AS
SELECT *  FROM tarea10000hs
WHERE id_tarea LIKE '%REP%'
WITH LOCAL CHECK OPTION;

SELECT *
FROM tarea10000hs;
select *
FROM tarea10000rep;
SELECT *
FROM tarea;

INSERT INTO tarea10000rep (id_tarea, nombre_tarea, min_horas, max_horas)
     VALUES ( 'MGR', 'Org Salud', 18000, 20000);
INSERT INTO tarea10000hs (id_tarea, nombre_tarea, min_horas, max_horas)
     VALUES (  'REPA', 'Organiz Salud', 4000, 5500);
INSERT INTO tarea10000rep (id_tarea, nombre_tarea, min_horas, max_horas)
     VALUES ( 'CC_REP', 'Organizacion Salud', 8000, 9000);
INSERT INTO tarea10000hs (id_tarea, nombre_tarea, min_horas, max_horas)
     VALUES (  'ROM', 'Org Salud', 10000, 12000);
