WITH RECURSIVE x(v) AS (SELECT '
<actors>
	<actor>
		<first-name>Bud</first-name>
		<last-name>Spencer</last-name>
		<films>God Forgives... I Don’t, Double Trouble, They Call Him Bulldozer</films>
	</actor>
	<actor>
		<first-name>Terence</first-name>
		<last-name>Hill</last-name>
		<films>God Forgives... I Don’t, Double Trouble, Lucky Luke</films>
	</actor>
</actors>'::xml),
	actors(actor_id, first_name, last_name, films) AS (
		SELECT
			row_number() OVER (),
			(xpath('//first-name/text()', t.v))[1]::TEXT,
			(xpath('//last-name/text()' , t.v))[1]::TEXT,
			(xpath('//films/text()'     , t.v))[1]::TEXT
		FROM unnest(xpath('//actor', (SELECT v FROM x))) t(v)
	),
	films(actor_id, first_name, last_name, film_id, film) AS (
		SELECT actor_id, first_name, last_name, 1, 
			regexp_replace(films, ',.+', '')
		FROM actors
		UNION ALL
		SELECT actor_id, a.first_name, a.last_name, f.film_id + 1,
			regexp_replace(a.films, '.*' || f.film || ', ?(.*?)(,.+)?', '\1')
		FROM films AS f 
		JOIN actors AS a USING (actor_id)
		WHERE a.films NOT LIKE '%' || f.film
	)
SELECT * FROM films;
