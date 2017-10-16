/*


CREATE TABLE model._geopath_national_modelnet
(
  link_dir character varying(12) NOT NULL,
  a_id integer,
  b_id integer,
  link_id integer,
  st_name character varying(45),
  feat_id integer,
  ref_in_id integer,
  nref_in_id integer,
  func_class smallint,
  divider character varying(1),
  dir_travel character varying(1),
  ar_auto smallint,
  ar_bus smallint,
  ar_taxis smallint,
  ar_carpool smallint,
  ar_pedest smallint,
  ar_trucks smallint,
  ar_traff smallint,
  ar_deliv smallint,
  ar_emerveh smallint,
  ar_motor smallint,
  paved smallint,
  private smallint,
  frontage smallint,
  bridge smallint,
  tunnel smallint,
  ramp smallint,
  tollway smallint,
  poiaccess smallint,
  contracc smallint,
  roundabout smallint,
  ferry_type character varying(1),
  multidigit smallint,
  fourwhldr smallint,
  reversible smallint,
  expr_lane smallint,
  carpoolrd smallint,
  pub_access smallint,
  bgid character varying(12),
  area_type smallint,
  speed smallint,
  direction character varying(2),
  lanes smallint,
  spd_limit smallint,
  geom geometry(LineString,4326),
  CONSTRAINT _geopath_national_modelnet_pkey PRIMARY KEY (link_dir)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE model._geopath_national_modelnet
  OWNER TO postgres;

-- Index: model._geopath_national_modelnet_func

-- DROP INDEX model._geopath_national_modelnet_func;

CREATE INDEX _geopath_national_modelnet_func
  ON model._geopath_national_modelnet
  USING btree
  (func_class);

-- Index: model._geopath_national_modelnet_idx

-- DROP INDEX model._geopath_national_modelnet_idx;

CREATE INDEX _geopath_national_modelnet_idx
  ON model._geopath_national_modelnet
  USING gist
  (geom);

-- Index: model.modelnet_dirtravel_idx

-- DROP INDEX model.modelnet_dirtravel_idx;

CREATE INDEX modelnet_dirtravel_idx
  ON model._geopath_national_modelnet
  USING hash
  (dir_travel COLLATE pg_catalog."default");

-- Index: model.modelnet_linkid_idx

-- DROP INDEX model.modelnet_linkid_idx;

CREATE INDEX modelnet_linkid_idx
  ON model._geopath_national_modelnet
  USING hash
  (link_id);


*/


drop table if exists model._geopath_national_modelnet_priority1;--0.5 million
create table model._geopath_national_modelnet_priority1
as
select *  from model._geopath_national_modelnet 
where (contracc=1 or func_class<=1) and 
geom && st_setsrid(st_makeenvelope(-124.85, 24.39, -66.88, 49.39),4326)
;

drop table if exists model._geopath_national_modelnet_priority2;--1.4 million
create table model._geopath_national_modelnet_priority2
as
select *  from model._geopath_national_modelnet 
where (contracc=1 or func_class<=2) and
geom && st_setsrid(st_makeenvelope(-124.85, 24.39, -66.88, 49.39),4326)
;

drop table if exists model._geopath_national_modelnet_priority3;--3.6 million
create table model._geopath_national_modelnet_priority3
as
select *  from model._geopath_national_modelnet 
where (contracc=1 or func_class<=3) and
geom && st_setsrid(st_makeenvelope(-124.85, 24.39, -66.88, 49.39),4326)
;


drop table if exists model._geopath_national_modelnet_priority4; --11.5 million
create table model._geopath_national_modelnet_priority4
as
select *  from model._geopath_national_modelnet 
where (contracc=1 or func_class<=4) and
geom && st_setsrid(st_makeenvelope(-124.85, 24.39, -66.88, 49.39),4326)
;


------create tiling for modelnet priority 1, suitable for zoom level less than 6
------create tiling for modelnet priority 2, suitable for zoom level 7-9
------create tiling for modelnet priority 3, suitable for zoom level 10-12
------create tiling for modelnet priority 4, suitable for zoom level 13-15
------create tiling for modelnet all, suitable for zoom level 16


--st_setsrid(st_makeenvelope(-124.85, 24.39, -66.88, 49.39),4326)
--2 * 2

--###############################create grids####################################
drop table if exists tiles.grids cascade;
create table tiles.grids
as
select '1_1_0_0'::varchar as grid_id, 1 as grid_cols, 1 as grid_rows, 0 as x, 0 as y, 
st_setsrid(st_makeenvelope(-124.85, 24.39, -66.88, 49.39),4326)::geometry(polygon,4326) as geom,
box2d(st_setsrid(st_makeenvelope(-124.85, 24.39, -66.88, 49.39),4326)::geometry(polygon,4326)) as box2d
;
create index grids_idx on tiles.grids using gist(geom);



--DROP FUNCTION if exists tiles.create_xy_grids(integer,integer);
CREATE OR REPLACE FUNCTION tiles.create_xy_grids(cols integer, rows integer)
RETURNS setof tiles.grids
AS $$
DECLARE
	grid_rows int := rows;
	grid_cols int := cols;
	grid_id varchar; 
	x int;
	y int;
	x1 numeric;
	x2 numeric;
	y1 numeric;
	y2 numeric;
	geom geometry(polygon,4326);
	bounding box2d;
	extent record;
BEGIN
	select st_xmin(g.geom) as xmin, st_ymin(g.geom) as ymin, st_xmax(g.geom) as xmax, st_ymax(g.geom) as ymax 
		from tiles.grids as g INTO extent where g.grid_id = '1_1_0_0' limit 1;
	FOR x IN 0..(cols-1) LOOP
		FOR y IN 0..(rows-1) LOOP
			grid_id := (cols)::varchar || '_' || (rows)::varchar || '_' || x::varchar || '_' ||y::varchar;
			x1 := (extent.xmax - extent.xmin)/cols*x + extent.xmin;
			x2 := (extent.xmax - extent.xmin)/cols*(x+1) + extent.xmin;
			y1 := (extent.ymax - extent.ymin)/rows*y + extent.ymin;
			y2 := (extent.ymax - extent.ymin)/rows*(y+1) + extent.ymin;
			geom := st_setsrid(st_makeenvelope(x1, y1, x2, y2),4326)::geometry(polygon,4326); 
			bounding := box2d(geom); 
			RETURN QUERY (select grid_id, grid_cols, grid_rows, x, y, geom, bounding);
		END LOOP;
	END LOOP;

END
$$ LANGUAGE 'plpgsql'
;

DELETE FROM tiles.grids WHERE grid_id <> '1_1_0_0';

INSERT INTO tiles.grids
SELECT * from tiles.create_xy_grids(12,5);


select * from tiles.grids;


--###############################create national links tables with priorities####################################
drop table if exists tiles.national_all;
create table tiles.national_all
as
select m.*
from model._geopath_national_modelnet as m,
 (select * from tiles.grids where grid_id = '1_1_0_0' limit 1) as g
where m.geom && g.geom
;
create index national_idx on tiles.national_all using gist(geom);
create index national_all_func on tiles.national_all using btree(func_class);
create index national_all_contrac on tiles.national_all using btree(contracc);

--priority 0
drop table if exists tiles.national_priority0; 
create table tiles.national_priority0
as
select *  from tiles.national_all 
where (contracc=1 or func_class<=1) and lanes>=5
; 
create index national_priority0_idx on tiles.national_priority0 using gist(geom);


--priority 1
drop table if exists tiles.national_priority1; 
create table tiles.national_priority1
as
select *  from tiles.national_all 
where (contracc=1 or func_class<=1)
; 
create index national_priority1_idx on tiles.national_priority1 using gist(geom);

--priority 2
drop table if exists tiles.national_priority2; 
create table tiles.national_priority2
as
select *  from tiles.national_all 
where (contracc=1 or func_class<=2)
; 
create index national_priority2_idx on tiles.national_priority2 using gist(geom);

--priority 3
drop table if exists tiles.national_priority3;--3.6 million
create table tiles.national_priority3
as
select *  from tiles.national_all 
where (contracc=1 or func_class<=3)
; 
create index national_priority3_idx on tiles.national_priority3 using gist(geom);

--priority 4
drop table if exists tiles.national_priority4; --11.5 million
create table tiles.national_priority4
as
select *  from tiles.national_all
where (contracc=1 or func_class<=4) 
;
create index national_priority4_idx on tiles.national_priority4 using gist(geom);



--###############################create tiles####################################
--DROP FUNCTION if exists tiles.create_vts(integer,integer);
CREATE OR REPLACE FUNCTION tiles.create_tile(national_table varchar, grid_id varchar)
RETURNS BIGINT
AS $$
DECLARE
	table_name varchar := national_table || '_vt_' || grid_id;
	query_string varchar;
	return_val bigint;
BEGIN
	query_string := 'drop table if exists tiles.'||table_name||'; ';
	query_string := query_string || 'create table tiles.'||table_name
		||' as select * from tiles.'||national_table||' where geom && (select geom from tiles.grids where grid_id = '''
		||grid_id||'''); ';
	--raise notice '%', query_string;
	EXECUTE query_string;
	EXECUTE format('select count(*) from tiles.%s', table_name) INTO return_val;
	RETURN return_val;
END
$$ LANGUAGE 'plpgsql'
;

CREATE OR REPLACE FUNCTION tiles.drop_tile(national_table varchar, grid_id varchar)
RETURNS VOID
AS $$
DECLARE
	table_name varchar := national_table || '_vt_' || grid_id;
	query_string varchar;
BEGIN
	query_string := 'drop table if exists tiles.'||table_name||'; ';
	--raise notice '%', query_string;
	EXECUTE query_string;

END
$$ LANGUAGE 'plpgsql'
;



CREATE OR REPLACE FUNCTION tiles.create_vts(national_table varchar, cols integer, rows integer)
RETURNS VOID
AS $$
DECLARE
	grid_id varchar; 
	x int;
	y int;
	link_count bigint;
	stats_table varchar := national_table || '_vt_' || (cols)::varchar || '_' || (rows)::varchar ||'_stats';
	create_table_string varchar;
BEGIN
	create_table_string := 'DROP TABLE IF EXISTS tiles.' || stats_table || '; ' 
		||'CREATE TABLE tiles.' || stats_table || ' (grid_id varchar, grid_cols int, grid_rows int, link_count bigint);';
	EXECUTE create_table_string;
	FOR x IN 0..(cols-1) LOOP
		FOR y IN 0..(rows-1) LOOP
			grid_id := (cols)::varchar || '_' || (rows)::varchar || '_' || x::varchar || '_' ||y::varchar;
			SELECT tiles.create_tile(national_table,grid_id) INTO link_count;
			EXECUTE format('INSERT INTO tiles.%s VALUES(''%s'', %s, %s, %s)', stats_table, grid_id, x, y, link_count);
		END LOOP;
	END LOOP;
END
$$ LANGUAGE 'plpgsql'
;


CREATE OR REPLACE FUNCTION tiles.create_vts(national_table varchar, cols integer, rows integer)
RETURNS VOID
AS $$
DECLARE
	grid_id varchar; 
	x int;
	y int;
	link_count bigint;
	stats_table varchar := national_table || '_vt_' || (cols)::varchar || '_' || (rows)::varchar ||'_stats';
	create_table_string varchar;
	res_string varchar;
BEGIN
	create_table_string := 'DROP TABLE IF EXISTS tiles.' || stats_table || '; ' 
		||'CREATE TABLE tiles.' || stats_table || ' (grid_id varchar, grid_cols int, grid_rows int, link_count bigint);';
	--PERFORM dblink_disconnect('dblink_trans');
	PERFORM dblink_connect('dblink_trans','dbname=here_db_2016r3 port=5432 user=jupiter password=Datam1ner');
	PERFORM dblink('dblink_trans', create_table_string);
	--PERFORM dblink('dblink_trans','COMMIT;');
	--PERFORM dblink_disconnect('dblink_trans');
	FOR x IN 0..(cols-1) LOOP
		--PERFORM dblink_connect('dblink_trans','dbname=here_db_2016r3 port=5432 user=jupiter password=Datam1ner');
		FOR y IN 0..(rows-1) LOOP
			grid_id := (cols)::varchar || '_' || (rows)::varchar || '_' || x::varchar || '_' ||y::varchar;
			--SELECT tiles.create_tile(national_table,grid_id) INTO link_count;
			res_string := format('INSERT INTO tiles.%s VALUES(''%s'', %s, %s, (select tiles.create_tile(''%s'', ''%s'')));', stats_table, grid_id, x, y, national_table,grid_id);
			RAISE NOTICE '%', res_string;
			PERFORM dblink('dblink_trans', res_string);
			--COMMIT;
		END LOOP;
		PERFORM dblink('dblink_trans','COMMIT;');
	END LOOP;
	PERFORM dblink_disconnect('dblink_trans');
END
$$ LANGUAGE 'plpgsql'
;

CREATE OR REPLACE FUNCTION tiles.drop_vts(national_table varchar, cols integer, rows integer)
RETURNS VOID
AS $$
DECLARE
	grid_id varchar; 
	x int;
	y int;
	stats_table varchar := national_table || '_vt_' || (cols)::varchar || '_' || (rows)::varchar ||'_stats';
	drop_table_string varchar;
BEGIN
	drop_table_string := 'DROP TABLE IF EXISTS tiles.' || stats_table || ';' ;
	EXECUTE drop_table_string;
	FOR x IN 0..(cols-1) LOOP
		FOR y IN 0..(rows-1) LOOP
			grid_id := (cols)::varchar || '_' || (rows)::varchar || '_' || x::varchar || '_' ||y::varchar;
			PERFORM tiles.drop_tile(national_table,grid_id);
		END LOOP;
	END LOOP;
END
$$ LANGUAGE 'plpgsql'
;






select * from information_schema.tables where table_name like 'national%stats'



--#######################################Add some grids###################################
DELETE FROM tiles.grids WHERE grid_id <> '1_1_0_0';
INSERT INTO tiles.grids SELECT * from tiles.create_xy_grids(2,2);
INSERT INTO tiles.grids SELECT * from tiles.create_xy_grids(4,2);
INSERT INTO tiles.grids SELECT * from tiles.create_xy_grids(8,4);
INSERT INTO tiles.grids SELECT * from tiles.create_xy_grids(12,5);
INSERT INTO tiles.grids SELECT * from tiles.create_xy_grids(24,10);
INSERT INTO tiles.grids SELECT * from tiles.create_xy_grids(50,20);
INSERT INTO tiles.grids SELECT * from tiles.create_xy_grids(150,60);
INSERT INTO tiles.grids SELECT * from tiles.create_xy_grids(450,180);
select * from tiles.grids;
--#######################################Create Vector Tiles##############################
select tiles.create_vts('national_priority0', 1, 1);
select tiles.create_vts('national_priority1', 2, 2);
select tiles.create_vts('national_priority1', 4, 2);
select tiles.create_vts('national_priority1', 8, 4);
select tiles.create_vts('national_priority2', 12, 5);
select tiles.create_vts('national_priority2', 24, 10);
select tiles.create_vts('national_priority3', 12, 5);
select tiles.create_vts('national_priority3', 24, 10);
select tiles.create_vts('national_priority4', 50, 20);
select tiles.create_vts('national_priority4', 50, 20);

select tiles.create_vts('national_priority4', 150, 60);
select tiles.create_vts('national_all', 450,180);
select tiles.drop_vts('national_all', 450,180);



select * from tiles.national_priority1_vt_8_4_stats;
select * from tiles.national_priority2_vt_24_10_stats;
select * from tiles.national_priority3_vt_50_20_stats;
select * from tiles.national_priority4_vt_150_60_stats;
select * from tiles.national_all_vt_450_180_stats;
select * from tiles.national_priority0_vt_1_1_stats;

--#################################################Render tiles###############################

CREATE OR REPLACE FUNCTION tiles.list_xy_grids(cols integer, rows integer, x_coor numeric, y_coor numeric)
RETURNS table(x int, y int)
AS $$
DECLARE
	x_grid int;
	y_grid int;
	extent record;
BEGIN
	select st_xmin(g.geom) as xmin, st_ymin(g.geom) as ymin, st_xmax(g.geom) as xmax, st_ymax(g.geom) as ymax 
		from tiles.grids as g INTO extent where g.grid_id = '1_1_0_0' limit 1;

	x_grid := floor((x_coor - extent.xmin)/((extent.xmax - extent.xmin)/cols));
	y_grid := floor((y_coor - extent.ymin)/((extent.ymax - extent.ymin)/rows));

	IF x_grid<=0 THEN x_grid :=0; END IF;
	IF x_grid>=cols-1 THEN x_grid :=cols-1; END IF;
	IF y_grid<=0 THEN y_grid :=0; END IF;
	IF y_grid>=rows-1 THEN y_grid :=rows-1; END IF;
	RETURN QUERY EXECUTE format('select %s as x, %s as y', x_grid, y_grid);
	
	
END
$$ LANGUAGE 'plpgsql'
;


CREATE OR REPLACE FUNCTION tiles.render_vts_byextent(national_table varchar, cols integer, rows integer, xmin numeric, ymin numeric, xmax numeric, ymax numeric)
RETURNS setof tiles.national_all
AS $$
DECLARE
	xmin_grid int;
	ymin_grid int;
	xmax_grid int;
	ymax_grid int;
	x int;
	y int;
	grid_id varchar;
	table_name varchar;
	res tiles.national_all%ROWTYPE;
BEGIN
	EXECUTE format('SELECT x,y FROM tiles.list_xy_grids(%s, %s, %s, %s)', cols, rows, xmin, ymin) INTO xmin_grid, ymin_grid;
	EXECUTE format('SELECT x,y FROM tiles.list_xy_grids(%s, %s, %s, %s)', cols, rows, xmax, ymax) INTO xmax_grid, ymax_grid;
	
	FOR x IN xmin_grid..(xmax_grid) LOOP
		FOR y IN ymin_grid..(ymax_grid) LOOP
			grid_id := (cols)::varchar || '_' || (rows)::varchar || '_' || x::varchar || '_' ||y::varchar;
			table_name := national_table || '_vt_' || grid_id;
			--EXECUTE format('SELECT * FROM tiles.%s ', table_name) INTO res;
			RETURN QUERY EXECUTE format('SELECT * FROM tiles.%s', table_name);
			RAISE NOTICE 'SELECT * FROM tiles.%', table_name;
		END LOOP;
	END LOOP;
	--RETURN res;
END
$$ LANGUAGE 'plpgsql'
;


CREATE OR REPLACE FUNCTION tiles.render_xy_grids(national_table varchar, cols integer, rows integer, xmin numeric, ymin numeric, xmax numeric, ymax numeric)
RETURNS table(grid_xmin int, grid_ymin int, grid_xmax int, grid_ymax int)
AS $$
DECLARE
	xmin_grid int;
	ymin_grid int;
	xmax_grid int;
	ymax_grid int;
BEGIN
	EXECUTE format('SELECT x,y FROM tiles.list_xy_grids(%s, %s, %s, %s)', cols, rows, xmin, ymin) INTO xmin_grid, ymin_grid;
	EXECUTE format('SELECT x,y FROM tiles.list_xy_grids(%s, %s, %s, %s)', cols, rows, xmax, ymax) INTO xmax_grid, ymax_grid;
	RETURN QUERY EXECUTE format('select %s as grid_xmin, %s as grid_ymin, %s as grid_xmax, %s as grid_ymax', xmin_grid, ymin_grid, xmax_grid, ymax_grid);
END
$$ LANGUAGE 'plpgsql'
;


select * from tiles.render_xy_grids('national_priority3', 24, 10, -124, 25,-124, 25)


CREATE OR REPLACE FUNCTION tiles.render_vts(national_table varchar, cols integer, rows integer, grid_xmin int, grid_ymin int, grid_xmax int, grid_ymax int)
RETURNS setof tiles.national_all
AS $$
DECLARE
	x int;
	y int;
	grid_id varchar;
	table_name varchar;
	res tiles.national_all%ROWTYPE;
BEGIN
	FOR x IN grid_xmin..(grid_xmax) LOOP
		FOR y IN grid_ymin..(grid_ymax) LOOP
			grid_id := (cols)::varchar || '_' || (rows)::varchar || '_' || x::varchar || '_' ||y::varchar;
			table_name := national_table || '_vt_' || grid_id;
			--EXECUTE format('SELECT * FROM tiles.%s ', table_name) INTO res;
			RETURN QUERY EXECUTE format('SELECT * FROM tiles.%s', table_name);
			RAISE NOTICE 'SELECT * FROM tiles.%', table_name;
		END LOOP;
	END LOOP;

END
$$ LANGUAGE 'plpgsql'
;


