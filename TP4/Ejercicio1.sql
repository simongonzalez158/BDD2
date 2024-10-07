SELECT *
FROM ARTICULO_TP4;

SELECT *
FROM ENVIO_TP4;

SELECT *
FROM PROVEEDOR_TP4;

-- Table: ARTICULO
CREATE TABLE ARTICULO_TP4 (
    id_articulo varchar(10)  NOT NULL,
    descripcion varchar(30)  NOT NULL,
    precio decimal(8,2)  NOT NULL,
    peso decimal(5,2)  NULL,
    ciudad varchar(30)  NOT NULL,
    CONSTRAINT ARTICULO_pk PRIMARY KEY (id_articulo)
);

-- Table: ENVIO
CREATE TABLE ENVIO_TP4 (
    id_proveedor varchar(10)  NOT NULL,
    id_articulo varchar(10)  NOT NULL,
    cantidad int  NOT NULL,
    CONSTRAINT ENVIO_pk PRIMARY KEY (id_proveedor,id_articulo)
);

-- Table: PROVEEDOR
CREATE TABLE PROVEEDOR_TP4 (
    id_proveedor varchar(10)  NOT NULL,
    nombre varchar(30)  NOT NULL,
    rubro varchar(15)  NOT NULL,
    ciudad varchar(30)  NOT NULL,
    CONSTRAINT PROVEEDOR_pk PRIMARY KEY (id_proveedor)
);

-- foreign keys
-- Reference: ENVIO_ARTICULO (table: ENVIO)
ALTER TABLE ENVIO_TP4 ADD CONSTRAINT ENVIO_ARTICULO
    FOREIGN KEY (id_articulo)
    REFERENCES ARTICULO_TP4 (id_articulo)
    NOT DEFERRABLE
    INITIALLY IMMEDIATE
;

-- Reference: ENVIO_PROVEEDOR (table: ENVIO)
ALTER TABLE ENVIO_TP4 ADD CONSTRAINT ENVIO_PROVEEDOR
    FOREIGN KEY (id_proveedor)
    REFERENCES PROVEEDOR_TP4 (id_proveedor)
    NOT DEFERRABLE
    INITIALLY IMMEDIATE
;

--> a)
CREATE VIEW ENVIOS500 AS
    SELECT *
    FROM ENVIO_TP4
    WHERE cantidad>=500;

--> b)
CREATE VIEW ENVIOS500_M AS
    SELECT *
    FROM ENVIOS500
    WHERE cantidad <= 999;

--> c)
CREATE VIEW RUBROS_PROV AS
    SELECT distinct rubro
    FROM PROVEEDOR_TP4
    WHERE ciudad = 'Tandil';

--> d)
CREATE VIEW ENVIOS_PROV AS
    SELECT p.id_proveedor, p.nombre, SUM(e.cantidad) AS "total de unidades"
    FROM PROVEEDOR_TP4 p JOIN ENVIO_TP4 E on p.id_proveedor = E.id_proveedor
    GROUP BY p.id_proveedor, p.nombre;

INSERT INTO ARTICULO_TP4 (id_articulo, descripcion, precio, peso, ciudad)
VALUES
('A1', 'Articulo 1', 100.00, 1.50, 'Buenos Aires'),
('A2', 'Articulo 2', 200.00, 2.00, 'Tandil'),
('A3', 'Articulo 3', 150.00, 1.75, 'Mar del Plata');

INSERT INTO PROVEEDOR_TP4 (id_proveedor, nombre, rubro, ciudad)
VALUES
('P1', 'Proveedor 1', 'Electronica', 'Tandil'),
('P2', 'Proveedor 2', 'Muebles', 'Buenos Aires'),
('P3', 'Proveedor 3', 'Textil', 'Tandil'),
('P4', 'Proveedor 4', 'Electronica', 'Mar del Plata');

INSERT INTO ENVIO_TP4 (id_proveedor, id_articulo, cantidad)
VALUES
('P1', 'A1', 500),
('P1', 'A2', 800),
('P2', 'A3', 300),
('P3', 'A1', 999),
('P4', 'A2', 1200);

SELECT *
FROM ENVIOS500;

SELECT *
FROM ENVIOS500_M;

SELECT *
FROM RUBROS_PROV;

SELECT *
FROM ENVIOS_PROV;

-- actualiza
INSERT INTO ENVIOS500 VALUES ('P5', 'A2', 600);

-- actualiza
UPDATE ENVIOS500
SET cantidad = 550
WHERE id_proveedor = 'P1' AND id_articulo = 'A1';

-- actualiza
UPDATE ENVIOS500_M
SET cantidad = 720
WHERE id_proveedor = 'P5' AND id_articulo = 'A2';

-- se reflejan los cambios en la tabla
SELECT *
FROM ENVIO_TP4;

-- de tabla base se actualiza a vista
INSERT INTO PROVEEDOR_TP4 (id_proveedor, nombre, rubro, ciudad)
VALUES
('P5', 'Proveedor 5', 'Bicicleteria', 'Tandil');

-- de vista a tabla base, no permite actualizar (no es actualizable)
INSERT INTO RUBROS_PROV (rubro)
VALUES ('Juguetes');

-- no deja actualizar
UPDATE RUBROS_PROV
SET rubro = 'Alimentos'
WHERE rubro = 'Electronica';

SELECT *
FROM PROVEEDOR_TP4;

-- no actualiza
UPDATE ENVIOS_PROV
SET "total de unidades"= 2000
WHERE id_proveedor = 'P1';

-- funciona y borra la tupla de la tabla ENVIO_TP4
DELETE FROM ENVIOS500
WHERE id_proveedor = 'P5' AND id_articulo = 'A2';

-- no funciona
DELETE FROM ENVIOS_PROV
WHERE id_proveedor = 'P1';

-- Si una vista es actualizable, también debería soportar INSERT, UPDATE, y DELETE.
-- Las vistas no actualizables (por tener GROUP BY, DISTINCT, etc.) no permiten ninguna de estas tres operaciones.