-- 3a. Vista1, que contenga el saldo de cada uno de los clientes menores de 30 años de la ciudad ‘Napoli, que posean más de 3 servicios.

-- Esta vista es automáticamente actualizable, ya que no utiliza ensambles, ni funciones de agregación o de agrupamiento para su resolución.

CREATE VIEW vista1 AS
    SELECT c.saldo FROM cliente c
    WHERE exists(
        SELECT 1
        FROM equipo e
        WHERE e.id_cliente = c.id_cliente and exists(
            SELECT 1
            FROM servicio s
            WHERE s.id_servicio = e.id_servicio
            HAVING COUNT(s.id_servicio) > 3              -- es no actualizable ???
        )
    ) and exists(
        SELECT 1
        FROM persona p
        WHERE c.id_cliente = p.id_persona and AGE(p.fecha_nacimiento) < '30 years' and p.id_persona IN(
            select d.id_direccion from direccion d
            WHERE d.id_barrio IN (
                select 1 from barrio b
                where b.id_barrio IN(
                    select c.id_ciudad
                    from ciudad c
                    where c.nombre = 'Napoli'
                    )
                )
            )
    )
    -- WITH CHECK OPTION
    ;

CREATE VIEW vista1 AS
    SELECT c.id_cliente, c.saldo
    FROM cliente c
    JOIN persona p ON c.id_cliente = p.id_persona
    JOIN direccion d ON p.id_persona = d.id_persona
    JOIN barrio b ON d.id_barrio = b.id_barrio
    JOIN ciudad ci ON b.id_ciudad = ci.id_ciudad
    JOIN equipo e ON c.id_cliente = e.id_cliente
    JOIN servicio s ON e.id_servicio = s.id_servicio
    WHERE AGE(p.fecha_nacimiento) < '30 years' and ci.nombre = 'Napoli'
    GROUP BY c.id_cliente, c.saldo
    HAVING COUNT(e.id_servicio) > 3;

-- 3b. Vista2, con los datos de los clientes activos del sistema que hayan sido dados de alta en el año actual y que
-- poseen al menos un servicio activo, incluyendo el/los servicio/s activo/s que cada uno posee y su costo.

CREATE VIEW vista2 AS
    SELECT c.id_cliente, c.saldo, p.nombre, p.apellido, p.tipo, p.tipodoc, p.nrodoc, p.cuit, s.id_servicio, s.nombre, s.costo
    FROM cliente c
    JOIN persona p ON c.id_cliente = p.id_persona
    JOIN equipo e ON c.id_cliente = e.id_cliente
    JOIN servicio s ON e.id_servicio = s.id_servicio -- left join?? no, pq queremos los servicios no nulos

    WHERE p.activo and extract(year from p.fecha_alta) = extract(year from current_date) and s.activo; -- and e.id_Servicio not null ?
    --GROUP BY c.id_cliente, p.nombre, p.apellido, p.tipodoc, p.nrodoc, p.cuit
    --HAVING count(s.activo) >= 1; -- no es al pedo si pide los datos de los servicios activos??? pongo activo en el where y listo

-- La vista2 no es automaticamente actualizable porque la resolucion de ésta implica que se utilicen ensambles JOIN lo que en PostgreSQL no se permite

CREATE OR REPLACE FUNCTION fn_update_vista2()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE cliente
    SET saldo = NEW.saldo
    WHERE id_cliente = OLD.id_cliente;

    UPDATE persona
    SET nombre = new.nombre,
        apellido = new.apellido,
        tipo = new.tipo,
        tipodoc = new.tipodoc,
        nrodoc = new.nrodoc,
        cuit = new.cuit,
        fecha_alta = new.fecha_alta  -- where
    WHERE id_persona = OLD.id_cliente;

    UPDATE servicio
    SET nombre = new.nombre,
        costo = new.costo
    WHERE id_servicio = OLD.id_servicio;

    RETURN NEW;
end;
$$ language plpgsql;

CREATE TRIGGER tr_act_vista2
INSTEAD OF UPDATE ON vista2
FOR EACH ROW
EXECUTE FUNCTION fn_update_vista2();

CREATE OR REPLACE FUNCTION fn_insert_vista2()
RETURNS TRIGGER AS $$               -- falta servicio
BEGIN
    INSERT INTO persona(id_persona, tipo, tipodoc, nrodoc, nombre, apellido, fecha_nacimiento, fecha_alta, fecha_baja, cuit, activo, mail, telef_area, telef_numero) -- activo true???
    VALUES (new.id_persona, new.tipo, new.tipodoc, new.nrodoc, new.nombre, new.apellido, new.fecha_nacimiento, new.fecha_alta, new.fecha_baja, new.cuit, true, new.mail, new.telef_area, new.telef_numero);

    INSERT INTO cliente(id_cliente, saldo)
    VALUES (new.id_cliente, new.saldo);

    INSERT INTO equipo (id_equipo, nombre, ip, ap, id_servicio, id_cliente, fecha_alta, fecha_baja, tipo_conexion, tipo_asignacion)
    VALUES(new.id_equipo, new.nombre, new.ip, new.ap, new.id_servicio, new.id_cliente, new.fecha_alta, new.fecha_baja, new.tipo_conexion, new.tipo_asignacion);

    RETURN new;
end;
$$ language plpgsql;

CREATE TRIGGER tr_insert_vista2
INSTEAD OF INSERT ON vista2
FOR EACH ROW
EXECUTE FUNCTION fn_insert_vista2();

CREATE OR REPLACE FUNCTION fn_delete_vista2()       -- falta servicio
RETURNS TRIGGER AS $$
BEGIN
    delete from equipo where id_cliente = old.id_cliente;
    delete from cliente where id_cliente = old.id_cliente;
    delete from persona where id_persona = old.id_cliente;

    RETURN old;
end;
$$ language plpgsql;

CREATE TRIGGER tr_delete_vista2
INSTEAD OF DELETE ON vista2
FOR EACH ROW
EXECUTE FUNCTION fn_delete_vista2();

-- 3c. Vista3, que contenga, por cada uno de los servicios periódicos registrados en el sistema, los datos del servicio
-- y el monto facturado mensualmente durante los últimos 5 años, ordenado por servicio, año, mes y monto.

-- esta vista no es automaticamente actualizable por los datos que pide.
-- Para realizarse se deben utilizar ensambles, funciones de agregacion y de agrupamiento

CREATE VIEW vista3 AS
    SELECT s.id_servicio, s.nombre, s.costo, extract(year from c.fecha), extract(month from c.fecha), SUM(l.cantidad * l.importe) AS monto_facturado
    FROM servicio s
    JOIN lineacomprobante l ON s.id_servicio = l.id_servicio
    JOIN comprobante c ON l.id_comp = c.id_comp and l.id_tcomp = c.id_tcomp
    WHERE s.periodico and (c.fecha >= current_date - INTERVAL '5 years') and c.fecha <= current_date
    GROUP BY s.id_servicio, s.nombre, s.costo, c.fecha
    ORDER BY s.id_servicio, extract(year from c.fecha), extract(month from c.fecha), monto_facturado;

CREATE OR REPLACE FUNCTION fn_update_vista3()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE servicio
    SET nombre = new.nombre,
        costo = new.costo,
        periodico = new.periodico   -- por el where. va o no va? Si periodico afecta los datos que aparecen en la vista (debido al filtro WHERE s.periodico), deberías incluirlo en el UPDATE para que los cambios de periodicidad reflejen si el servicio sigue o no en la vista.
    WHERE id_servicio = OLD.id_servicio;

    UPDATE lineacomprobante
    SET cantidad = new.cantidad,
        importe = new.importe
    WHERE nro_linea = OLD.nro_linea and id_comp = OLD.id_comp and id_tcomp = OLD.id_tcomp;

    UPDATE comprobante
    SET fecha = new.fecha
    WHERE id_comp = old.id_comp and id_tcomp = old.id_tcomp;

    RETURN NEW;
end;
$$ language 'plpgsql';

CREATE TRIGGER tr_update_vista3
INSTEAD OF UPDATE ON vista3
FOR EACH ROW
EXECUTE FUNCTION fn_update_vista3();

CREATE OR REPLACE FUNCTION fn_insert_vista3()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO servicio(id_servicio, nombre, periodico, costo, intervalo, tipo_intervalo, activo, id_cat)
    VALUES (new.id_servicio, new.nombre, new.periodico, new.costo, new.intervalo, new.tipo_intervalo, new.activo, new.id_cat);

    INSERT INTO lineacomprobante(nro_linea, id_comp, id_tcomp, descripcion, cantidad, importe, id_servicio)
    VALUES (new.nro_linea, new.id_comp, new.id_tcomp, new.descripcion, new.cantidad, new.importe, new.id_servicio);

    INSERT INTO comprobante(id_comp, id_tcomp, fecha, comentario, estado, fecha_vencimiento, id_turno, importe, id_cliente, id_lugar)
    VALUES (new.id_comp, new.id_tcomp, new.fecha, new.comentario, new.estado, new.fecha_vencimiento, new.id_turno, new.importe, new.id_cliente, new.id_lugar);

    RETURN NEW;
end;
$$ language 'plpgsql';

CREATE TRIGGER tr_insert_vista3
INSTEAD OF INSERT ON vista3
FOR EACH ROW
EXECUTE FUNCTION fn_insert_vista3();

CREATE OR REPLACE FUNCTION fn_delete_vista3()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM servicio where id_servicio = old.id_servicio;
    DELETE FROM lineacomprobante where nro_linea = old.nro_linea;
    DELETE FROM comprobante where id_comp = old.id_comp and id_tcomp = old.id_tcomp;

    RETURN OLD;
end;
$$ language 'plpgsql';

CREATE TRIGGER tr_delete_vista3
INSTEAD OF DELETE ON vista3
FOR EACH ROW
EXECUTE FUNCTION fn_delete_vista3();