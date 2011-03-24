CREATE OR REPLACE FUNCTION top.partial_update(_c integer, _id bigint, _partial_val character varying, _index integer[])
  RETURNS character varying AS
$BODY$DECLARE
arr varchar[];
new_val_arr varchar[] := ARRAY[];
i integer;
max_index integer := 0;
BEGIN

SELECT  regexp_split_to_table(regexp_replace(regexp_replace(value_derived,'^.{',''),'}.$',''),'},{') 
  INTO arr
  FROM attribute.attribute where id = _id and c = _c;
IF arr IS NULL 
  THEN RETURN _partial_val;
END IF;

FOR i IN 1..array_upper(_index,1) LOOP
  IF max_index < _index[i]
    THEN max_index := _index[i];
  END IF;
END LOOP;
-- ...
return 'a';
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION top.partial_update(integer, bigint, character varying, integer[]) OWNER TO postgres;
