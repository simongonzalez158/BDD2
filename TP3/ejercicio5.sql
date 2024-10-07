CREATE TABLE IF NOT EXISTS INFO_HISTORICA (
    id_empleado int NOT NULL,
    tiempo_sistema time NOT NULL,
    tiempo_promedio time NOT NULL
);

alter table empleado add column fecha_alta date; -- agregamos la columna de fecha de alta a la tabla de empleado

create table his_empleado (
    --creacion de la tabla empleado
    id_empleado numeric(6,0),
    fecha_inicio date,
    fecha_fin date,
    id_distribuidor numeric(5,0),
    id_departamento numeric(4,0),
    CONSTRAINT pk_his_empleado PRIMARY KEY (id_empleado,fecha_inicio,id_distribuidor,id_departamento)
);

alter table his_empleado add constraint fk_empleado --agrega la fk de his_empleado con empleado
    foreign key (id_empleado)
        references empleado(id_empleado);

create or replace function fn_agEmp() returns trigger as $$ --ingresa a la tabla his_empleado el nuevo empleado al realizarse un insert en esa tabla
begin
    insert into his_empleado (id_empleado,fecha_inicio,id_distribuidor,id_departamento) values (new.id_empleado,current_date,new.id_distribuidor,new.id_departamento);
    return new;
end;
$$ language 'plpgsql';

create or replace trigger tr_his_empleado --trigger para cuando se hace un insert en empleado
    after insert
    on empleado
    for each row
execute function fn_agEmp();

create or replace function fn_modEmp() returns trigger as $$ -- la funcion se encarga de, cuando hay un update en el (id_dpto,id_dist), agregar la fecha de fin en his_empleado y crear una nueva entrada en esa tabla para ese empleado
begin
    update his_empleado set fecha_fin = current_date
    where (id_empleado = old.id_empleado) and (fecha_fin is null)  and (id_distribuidor = old.id_distribuidor) and (id_departamento = old.id_departamento);
    insert into his_empleado (id_empleado,fecha_inicio,id_distribuidor,id_departamento) values (new.id_empleado,current_date,new.id_distribuidor,new.id_departamento);
    return new;
end;
$$ language 'plpgsql';

create or replace trigger tr_his_empleado2 --trigger q se activa en update
    before update of id_distribuidor, id_departamento
    on empleado
    for each row
execute function fn_modEmp();

create or replace function fn_elimEmp() returns trigger as $$ --funcion q elimina de la tabla historica el empleado al q se le hizo delete en la tabla empleado (asumimos q se quiere esto, se puede asumir cualquier cosa nos dijieron los profes)
begin
    delete from his_empleado where id_empleado = old.id_empleado;
    return old;
end;
$$ language 'plpgsql';

create or replace trigger tr_his_empleado3 --trigger q se activa al detectar un delete en empleado
    before delete
    on empleado
    for each row
execute function fn_elimEmp();

create or replace procedure actualizar_historico()
--procedure q actualiza tanto empleado como his_empleado, la idea es usarla una unica vez, luego de crear la nueva columna en empleado y para cargarle los valores a his_empleado
    language 'plpgsql' as $$
begin
    update empleado set fecha_alta = current_date;
    insert into his_empleado select id_empleado, current_date, '2026-7-18', id_departamento, id_distribuidor from empleado;
end
$$;

call actualizar_historico();

select * from departamento
    limit 2;

select * from empleado where id_empleado =99999;

insert into empleado (id_empleado,id_distribuidor,id_departamento) values (99999,219,75);

select * from his_empleado where id_empleado =99999;

update empleado set id_departamento = 47,id_distribuidor = 117 where id_empleado = 99999;

delete from his_empleado;
delete from empleado where id_empleado = 99999;