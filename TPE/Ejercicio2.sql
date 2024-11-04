-- 2a. Al ser invocado (una vez por mes), para todos los servicios que son periódicos, se deben generar e insertar los registros asociados a la/s factura/s correspondiente/s a
-- los distintos clientes. Indicar si se deben proveer parámetros adicionales para su generación y, de ser así, cuales.

-- declararemos una funcion ya que esta puede ser invocada por alguien o algo.

CREATE OR REPLACE PROCEDURE pr_2a()
language plpgsql
as $$
DECLARE
    registro RECORD;
    id_factura BIGINT;
    seq_id_comprobante SERIAL; -- ???????????????????
BEGIN
    FOR registro IN
        SELECT c.id_cliente, s.id_servicio, s.costo, s.nombre AS nombre_servicio
        FROM cliente c
        JOIN persona p ON c.id_cliente = p.id_persona
        JOIN equipo e ON c.id_cliente = e.id_cliente
        JOIN servicio s ON e.id_servicio = s.id_servicio
        WHERE s.periodico and p.activo and e.fecha_baja IS NULL
    LOOP
        INSERT INTO comprobante(id_comp, id_tcomp, fecha, estado, importe, id_cliente) -- no puse comentario, fecha_vencimiento, id_turno, id_lugar
        VALUES (nextval('seq_id_comprobante'), 1, current_date, 'pendiente', 0, registro.id_cliente)
        RETURNING id_comp INTO id_factura;

        INSERT INTO lineacomprobante (nro_linea, id_comp, id_tcomp, descripcion, cantidad, importe, id_servicio)
        VALUES ( (
                SELECT coalesce(MAX(nro_linea),0) + 1
                FROM lineacomprobante
                WHERE id_comp = id_factura), id_factura, 1, registro.nombre_servicio, 1, registro.costo, registro.id_servicio);

        UPDATE comprobante
        SET importe = (SELECT SUM(importe) FROM lineacomprobante WHERE id_comp = id_factura)
        WHERE id_comp = id_factura;
        end loop;
end; $$;



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
            AVG(t.hasta - t.desde) AS tiempo_promedio,
            MAX(t.hasta - t.desde) AS tiempo_max

        FROM turno t JOIN personal per ON (t.id_personal = per.id_personal)
        JOIN persona p ON (per.id_personal = p.id_persona)
        JOIN comprobante c ON (t.id_turno = c.id_turno)
        WHERE t.desde BETWEEN (fecha_inicio, fecha_fin) --  and c.fecha BETWEEN (fecha_inicio, fecha_fin) redundante ?
        GROUP BY per.id_personal, p.nombre, p.apellido;
end;
$$
 -- personal sin turnos