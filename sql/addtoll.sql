
CREATE OR REPLACE FUNCTION tolls.addtoll(a_id integer, b_id integer, toll numeric)
  RETURNS integer AS
$BODY$
DECLARE
	rec int;
	toll_rec int;
	res int;
BEGIN
	EXECUTE format('SELECT count(*) FROM tolls.national_tolls 
	WHERE a_id = %s and b_id = %s', a_id, b_id) INTO rec;
	IF(rec = 0) THEN
		EXECUTE format('DROP TABLE IF EXISTS tolls.toll_temp; CREATE TABLE tolls.toll_temp as
		SELECT a_id, b_id, link_id, tollway, %s::numeric(10,2) as toll, geom FROM tiles.national_all 
		WHERE a_id = %s and b_id = %s; SELECT count(*) FROM tolls.toll_temp', toll, a_id, b_id) INTO toll_rec;

		IF(toll_rec >0) THEN
			--RAISE NOTICE '%s', toll_rec;
			EXECUTE format('INSERT INTO tolls.national_tolls SELECT * FROM tolls.toll_temp');
			EXECUTE format('INSERT INTO tolls.toll_update_history (a_id, b_id, toll, username, operation, save_time) VALUES (%s,%s,%s::numeric(10,2),',a_id,b_id,toll) || '''Ruzbeh'',''INSERT'','|| 'current_timestamp' || ')';
			res = 0; --add toll successfully
		ELSE
			res = 2; --cannot find corresponding link
		END IF;
		
	ELSE
		EXECUTE format('UPDATE tolls.national_tolls SET toll = %s WHERE a_id = %s and b_id = %s;',toll, a_id,b_id);
		EXECUTE format('INSERT INTO tolls.toll_update_history (a_id, b_id, toll, username, operation, save_time) VALUES (%s,%s,%s::numeric(10,2),',a_id,b_id,toll) || '''Ruzbeh'',''UPDATE'','|| 'current_timestamp' || ')';
		res = 1; --update toll record successfully
	END IF;
	RETURN res;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION tolls.addtoll(integer, integer, numeric)
  OWNER TO postgres;

  
CREATE OR REPLACE FUNCTION tolls.addtoll(a_id integer, b_id integer, toll numeric, username text)
  RETURNS integer AS
$BODY$
DECLARE
	rec int;
	toll_rec int;
	res int;
BEGIN
	EXECUTE format('SELECT count(*) FROM tolls.national_tolls 
	WHERE a_id = %s and b_id = %s', a_id, b_id) INTO rec;
	IF(rec = 0) THEN
		EXECUTE format('DROP TABLE IF EXISTS tolls.toll_temp; CREATE TABLE tolls.toll_temp as
		SELECT a_id, b_id, link_id, tollway, %s::numeric(10,2) as toll, geom FROM model._geopath_national_modelnet 
		WHERE a_id = %s and b_id = %s; SELECT count(*) FROM tolls.toll_temp', toll, a_id, b_id) INTO toll_rec;

		IF(toll_rec >0) THEN
			--RAISE NOTICE '%s', toll_rec;
			EXECUTE format('INSERT INTO tolls.national_tolls SELECT * FROM tolls.toll_temp');
			EXECUTE format('INSERT INTO tolls.toll_update_history (a_id, b_id, toll, username, operation, save_time) VALUES (%s,%s,%s::numeric(10,2),',a_id,b_id,toll) || '''' || username || ''',''INSERT'','|| 'current_timestamp' || ')';
			res = 0; --add toll successfully
		ELSE
			res = 2; --cannot find corresponding link
		END IF;
		
	ELSE
		EXECUTE format('UPDATE tolls.national_tolls SET toll = %s WHERE a_id = %s and b_id = %s;',toll, a_id,b_id);
		EXECUTE format('INSERT INTO tolls.toll_update_history (a_id, b_id, toll, username, operation, save_time) VALUES (%s,%s,%s::numeric(10,2),',a_id,b_id,toll) || '''' || username || ''',''UPDATE'','|| 'current_timestamp' || ')';
		res = 1; --update toll record successfully
	END IF;
	RETURN res;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION tolls.addtoll(integer, integer, numeric, text)
  OWNER TO postgres;

  
  