CREATE OR REPLACE FUNCTION top.append_to_array_value(_c integer, _id bigint, _vals_to_app character varying)
  RETURNS integer AS
$BODY$DECLARE
arr varchar[];
ret integer;
new_vals varchar;
max_index integer := 0;
BEGIN
SELECT  regexp_split_to_array(regexp_replace(value_derived,'.$',''),'},{')
  INTO arr
  FROM attribute.attribute WHERE id = _id and c = _c;
IF arr IS NULL THEN
  ret := 0;
  new_vals := _vals_to_app;
ELSE
  ret := array_upper(arr,1);
  new_vals := array_to_string(arr,'},{') || regexp_replace(_vals_to_app,'^.',',');
END IF;

UPDATE attribute.attribute SET value_derived = new_vals
  WHERE id = _id and c = _c;
RETURN ret;

END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION top.append_to_array_value(integer, bigint, character varying[]) OWNER TO postgres;
