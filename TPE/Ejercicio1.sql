 -- 1a. Las personas que no están activas deben tener establecida una fecha de baja, la cual se debe controlar que sea al menos 6 meses posterior a la de su alta.
ALTER TABLE persona
ADD CONSTRAINT chk_1a
CHECK ( activo = true or ((activo = false) and (fecha_baja IS NOT NULL) and ( fecha_baja >= fecha_alta+ INTERVAL '6 months') ) );

-- RI de tipo tupla: porque son restricciones sobre valores que puede tomar una combinación de atributos en una misma tupla, como son activo, fecha_baja y fecha_alta en la tabla Persona.

-- 1b. El importe de un comprobante debe coincidir con el total de los importes indicados en las líneas que lo conforman (si las tuviera).
-- RI general: porque la restricción se basa en un atributo de una tabla (importe de Comprobante), con el atributo de otra tabla (importe de LineaComprobante)

CREATE ASSERTION ast_1b
       CHECK ( NOT EXISTS( SELECT 1 FROM comprobante c
            JOIN lineacomprobante l ON (c.id_comp = l.id_comp and c.id_tcomp = l.id_tcomp)
            GROUP BY (c.id_comp, c.id_tcomp)
            HAVING SUM(l.importe) <> c.importe )
       );

CREATE OR REPLACE FUNCTION fn_1b()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(SELECT 1
              FROM comprobante c
                       JOIN lineacomprobante l on (c.id_comp = l.id_comp and c.id_tcomp = l.id_tcomp)
              WHERE c.id_comp = NEW.id_comp and c.id_tcomp = NEW.id_tcomp
              GROUP BY (c.id_comp, c.id_tcomp)
              HAVING coalesce(SUM(l.importe)*l.cantidad, 0) <> c.importe)                   -- considerar importe y cantidad de linea comprobante
    then
        RAISE EXCEPTION 'el importe del comprobante no coincide con el total de los importes en las correspondientes lineas comprobantes.';
    end if;
    return NEW;
end;
$$ language 'plpgsql';

CREATE TRIGGER tr_1b_comprobante
BEFORE INSERT OR UPDATE of importe ON comprobante
FOR EACH ROW
EXECUTE FUNCTION fn_1b();
-- se requieren controlar el evento de insercion en Comprobante porque puede que el importe de éste no coincidir con la suma de los importes por las cantidades de las correspondientes LineasComprobantes.
-- Tambien se debe controlar la actualizacion en importe de Comprobante porque al modificar este atributo ya podria no coincidir con los importes correspondientes de las LineasComprobantes

CREATE TRIGGER tr_1b_lineacomprobante -- sacar
BEFORE INSERT OR UPDATE of importe ON lineacomprobante
FOR EACH ROW
EXECUTE FUNCTION fn_1b();

-- 1c. Las IPs asignadas a los equipos no pueden ser compartidas entre diferentes clientes.
-- RI de tabla: ya que el atributo IP de la tabla Equipo para un id_cliente no puede repetirse en otras tuplas de la misma tabla donde id_cliente sea distinto.

ALTER TABLE equipo
ADD CONSTRAINT chk_1c
    CHECK (NOT EXISTS( SELECT 1 from equipo e1
        JOIN equipo e2 ON (e1.ip = e2.ip)
        WHERE (e1.id_cliente = e2.id_cliente)
    ));

ALTER TABLE equipo
ADD CONSTRAINT unique_ip_per_cliente
UNIQUE (ip, id_cliente);

 CREATE OR REPLACE FUNCTION fn_1c()
     RETURNS TRIGGER AS
 $$
 BEGIN
     IF (EXISTS(SELECT 1
                FROM equipo e1
                         JOIN equipo e2 ON (e1.ip = e2.ip)
                WHERE NEW.id_equipo = e1.id_equipo
                  and e1.id_cliente != e2.id_cliente)
         )
     then
         raise exception 'La IP asignada en el equipo ya esta en uso por otro cliente.';
     end if;
     return NEW;
 end;
 $$ language 'plpgsql';

CREATE OR REPLACE FUNCTION fn_1c() -- mas eficiente
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM equipo e
        WHERE e.ip = NEW.ip
          AND e.id_cliente <> NEW.id_cliente
    ) THEN
        RAISE EXCEPTION 'La IP asignada en el equipo ya está en uso por otro cliente.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_1c
BEFORE INSERT OR UPDATE OF IP on equipo
FOR EACH ROW
EXECUTE FUNCTION fn_1c();