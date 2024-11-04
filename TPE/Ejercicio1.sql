 -- 1a. Las personas que no están activas deben tener establecida una fecha de baja, la cual se debe controlar que sea al menos 6 meses posterior a la de su alta.
ALTER TABLE persona
ADD CONSTRAINT chk_1a
CHECK ( activo = true or ((activo = false) and (fecha_baja IS NOT NULL) and ( fecha_baja >= fecha_alta+ INTERVAL '6 months') ) );

-- RI de tipo tupla: porque son restricciones sobre valores que puede tomar una combinación de atributos en una misma tupla

-- 1b. El importe de un comprobante debe coincidir con el total de los importes indicados en las líneas que lo conforman (si las tuviera).
-- RI general: porque la restricción se basa en un atributo de una tabla (importe de Comprobante), con el atributo de otras tablas (importe de LineaComprobante)

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
              HAVING coalesce(SUM(l.importe), 0) <> c.importe)
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

CREATE TRIGGER tr_1b_lineacomprobante -- sacar
BEFORE INSERT OR UPDATE of importe ON lineacomprobante
FOR EACH ROW
EXECUTE FUNCTION fn_1b();

-- 1c. Las IPs asignadas a los equipos no pueden ser compartidas entre diferentes clientes.
-- RI general: el atributo IP de la tabla Equipo asociada a un Cliente, no puede repetirse en otros Clientes.

CREATE OR REPLACE FUNCTION fn_1c()
RETURNS TRIGGER AS $$
BEGIN
    IF ( EXISTS( SELECT 1 FROM equipo e1
                          JOIN equipo e2 ON (e1.ip = e2.ip)
                          WHERE NEW.id_equipo = e1.id_equipo and e1.id_cliente != e2.id_cliente)
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