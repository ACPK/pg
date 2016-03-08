SET client_min_messages TO ERROR;
BEGIN;
DROP SCHEMA IF EXISTS sivers CASCADE;
CREATE SCHEMA sivers;

CREATE TABLE things (
	id char(4) primary key,
	name varchar(32)
);


CREATE OR REPLACE FUNCTION random_string(length integer) RETURNS text AS $$
DECLARE
	chars text[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
	result text := '';
	i integer := 0;
BEGIN
	FOR i IN 1..length LOOP
		result := result || chars[1+random()*(array_length(chars, 1)-1)];
	END LOOP;
	RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION make_things_id() RETURNS TRIGGER AS $$
DECLARE
	new_id text := random_string(4);
BEGIN
	LOOP
		PERFORM 1 FROM things WHERE id = new_id;
		IF NOT FOUND THEN
			NEW.id := new_id;
			RETURN NEW;
		END IF;
		new_id := random_string(4);
	END LOOP;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER make_things_id BEFORE INSERT ON things FOR EACH ROW EXECUTE PROCEDURE make_things_id();


COMMIT;

