-- 2a. Al ser invocado (una vez por mes), para todos los servicios que son periódicos, se deben generar e insertar los registros asociados a la/s factura/s correspondiente/s a
-- los distintos clientes. Indicar si se deben proveer parámetros adicionales para su generación y, de ser así, cuales.

-- declararemos una funcion ya que esta puede ser invocada por alguien o algo.

CREATE SEQUENCE comprobante_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    NO CYCLE;

    CREATE SEQUENCE linea_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    NO CYCLE;

CREATE OR REPLACE PROCEDURE pr_2a()
LANGUAGE plpgsql
AS $$
DECLARE
    cliente record;
    equipo record;
    servicio record;
    factura_id bigint;
    cantidad int := 1;
BEGIN
    FOR cliente IN
        SELECT c.id_cliente
        FROM cliente c
        JOIN persona p ON c.id_cliente = p.id_persona
        WHERE p.activo
    LOOP
        INSERT INTO comprobante (id_comp, id_tcomp, fecha, comentario, estado, fecha_vencimiento, id_turno, importe, id_cliente, id_lugar)
        VALUES (nextval('comprobante_seq'), 1, now(), 'factura mensual', 'pendiente', now() + interval '30 days', null, 0, cliente.id_cliente, 1)
        RETURNING id_comp INTO factura_id;

        FOR equipo IN
            SELECT id_equipo, nombre, mac, ip, ap, id_servicio, id_cliente, fecha_alta, fecha_baja, tipo_conexion, tipo_asignacion
            FROM equipo e
            WHERE e.id_cliente = cliente.id_cliente
        LOOP
            FOR servicio IN
                SELECT id_servicio, nombre, periodico, costo, intervalo, tipo_intervalo, activo, id_cat
                FROM servicio s
                WHERE s.id_servicio = equipo.id_servicio AND s.periodico
            LOOP
                INSERT INTO lineacomprobante(nro_linea, id_comp, id_tcomp, descripcion, cantidad, importe, id_servicio)
                VALUES (nextval('linea_seq'), factura_id, 1, servicio.nombre, cantidad, servicio.costo, servicio.id_servicio);

                UPDATE comprobante
                SET importe = importe + (cantidad * servicio.costo)
                WHERE id_comp = factura_id;

            END LOOP;
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE comprobante_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    NO CYCLE;

    CREATE SEQUENCE linea_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    NO CYCLE;

CREATE OR REPLACE PROCEDURE pr_2a()
LANGUAGE plpgsql
AS $$
DECLARE
    cliente record;
    equipo record;
    servicio record;
    factura_id bigint;
    cantidad int;
BEGIN
    FOR cliente IN
        SELECT c.id_cliente
        FROM cliente c
        JOIN persona p ON c.id_cliente = p.id_persona
        WHERE p.activo
    LOOP
        INSERT INTO comprobante (id_comp, id_tcomp, fecha, comentario, estado, fecha_vencimiento, id_turno, importe, id_cliente, id_lugar)
        VALUES (nextval('comprobante_seq'), 1, now(), 'factura mensual', 'pendiente', now() + interval '30 days', null, 0, cliente.id_cliente, 1)
        RETURNING id_comp INTO factura_id;


            FOR servicio IN
                SELECT id_servicio, nombre, periodico, costo, intervalo, tipo_intervalo, activo, id_cat, count(*) into cantidad
                FROM servicio s
                WHERE s.id_servicio = equipo.id_servicio AND s.periodico
                GROUP BY id_servicio, nombre, periodico, costo, intervalo, tipo_intervalo, activo, id_cat
            LOOP
                INSERT INTO lineacomprobante(nro_linea, id_comp, id_tcomp, descripcion, cantidad, importe, id_servicio)
                VALUES (nextval('linea_seq'), factura_id, 1, servicio.nombre, cantidad, servicio.costo, servicio.id_servicio);

                UPDATE comprobante
                SET importe = importe + (cantidad * servicio.costo)
                WHERE id_comp = factura_id;

            END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 2b. Al ser invocado entre dos fechas cualesquiera genere un informe de los empleados (personal) junto con la cantidad de clientes distintos que
-- cada uno ha atendido en tal periodo y los tiempos promedio y máximo del conjunto de turnos atendidos en el periodo.

-- Elegimos realizar una funcion para resolver este servicio ya que puede ser invocada pasandole parámetros, es decir, las fechas requeridas para resolverlo.
-- Funciona de manera que primero la funcion se invoca con dos parámtetros: fecha_inicio y fecha_fin. Estos definen el periodo de tiempo a considerar.
-- Luego se parte de la tabla turno, seleccionando los registros que cumplan la condicion de que el empleado haya trabajado en el periodo requerido.
-- Despues se ensambla la tabla turno con personal para obtener el id_personal, y se ensambla con persona para obtener el nombre y apellido del empleado.
-- Por ultimo, al ensamblar la tabla Turno con Comprobante se obtienen los distintos clientes a los que el empleado atendió en el período.
-- Para calcular el tiempo promedio y maximo de los turnos atendidos en el periodo se hace la diferencia de t.hasta - t.desde para obtener el intervalo de tiempo que cada empleado trabajó.

CREATE OR REPLACE FUNCTION fn_2b(fecha_inicio DATE, fecha_fin DATE)
RETURNS TABLE (
    id_empleado int,
    nombre_apellido varchar(40),
    cant_clientes int,
    tiempo_promedio float,
    tiempo_max int
            )
    language plpgsql
AS $$
BEGIN
    return query
        SELECT
            per.id_personal AS id_empleado,
            CONCAT(p.nombre, ' ', p.apellido) AS nombre_apellido,
            count(distinct c.id_cliente) AS cant_clientes,
            --AVG(t.hasta - t.desde) AS tiempo_promedio,
            --MAX(t.hasta - t.desde) AS tiempo_max,

            AVG(CASE WHEN t.hasta IS NOT NULL THEN t.hasta - t.desde ELSE now() - t.desde END) AS tiempo_promedio,
            MAX(CASE WHEN t.hasta IS NOT NULL THEN t.hasta - t.desde ELSE now() - t.desde END) AS tiempo_max

        FROM turno t JOIN personal per ON t.id_personal = per.id_personal        -- right join para considerar personal sin turnos. en el sistema el personal siempre tiene un turno, el RIGHT JOIN no sería necesario. En su lugar, un INNER JOIN con personal y turno debería ser suficiente.
        JOIN persona p ON per.id_personal = p.id_persona
        JOIN comprobante c ON t.id_turno = c.id_turno
        WHERE t.desde BETWEEN (fecha_inicio, fecha_fin) -- and t.hasta is not null -- and c.fecha BETWEEN (fecha_inicio, fecha_fin) redundante ? si
        GROUP BY per.id_personal;
end;
$$
-- consideramos utilizar now() para calcular los tiempos promedio y máximo de los turnos que se estan realizando en este momento

-- para turnos ya finalizados o lo
 -- considerar personal sin turnos -- pero siempre un personal tiene turno. asi que porqué??
 -- el atributo 'hasta' nomas puede ser null. considerar???