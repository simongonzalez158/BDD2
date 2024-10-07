DROP VIEW ENVIOS500_M;
DROP VIEW ENVIOS500;

DELETE FROM envio_tp4;
DELETE FROM articulo_tp4;
DELETE FROM proveedor_tp4;

SELECT *
FROM articulo_tp4;
SELECT *
FROM envio_tp4;
SELECT *
FROM proveedor_tp4;
SELECT *
FROM envios500;

INSERT INTO ARTICULO_TP4 (id_articulo, descripcion, precio, peso, ciudad)
VALUES
('A1', 'Articulo 1', 100.00, 1.50, 'Buenos Aires'),
('A2', 'Articulo 2', 200.00, 2.00, 'Tandil');

INSERT INTO PROVEEDOR_TP4 (id_proveedor, nombre, rubro, ciudad)
VALUES
('P1', 'Proveedor 1', 'Electronica', 'Tandil'),
('P2', 'Proveedor 2', 'Muebles', 'Buenos Aires');

CREATE VIEW ENVIOS500 AS
    SELECT *
    FROM ENVIO_TP4
    WHERE cantidad>=500;

INSERT INTO ENVIOS500 VALUES ('P1', 'A1', 500);

INSERT INTO ENVIOS500 VALUES ('P2', 'A2', 300);

UPDATE ENVIOS500 SET cantidad=100 WHERE id_proveedor= 'P1';

UPDATE ENVIOS500 SET cantidad=1000 WHERE id_proveedor= 'P2';

INSERT INTO ENVIOS500 VALUES ('P3', 'A3', 700);

SELECT *
FROM envio_tp4;
SELECT *
FROM envios500;

DELETE FROM envio_tp4;
DROP VIEW ENVIOS500;

CREATE VIEW ENVIOS500 AS
    SELECT *
    FROM ENVIO_TP4
    WHERE cantidad>=500
    WITH CHECK OPTION;

INSERT INTO ENVIOS500 VALUES ('P1', 'A1', 500);

INSERT INTO ENVIOS500 VALUES ('P2', 'A2', 300);

UPDATE ENVIOS500 SET cantidad=100 WHERE id_proveedor= 'P1';

UPDATE ENVIOS500 SET cantidad=1200 WHERE id_proveedor= 'P2';

INSERT INTO ENVIOS500 VALUES ('P3', 'A3', 700);