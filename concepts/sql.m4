changequote(«, »)dnl
define(«NOTFOUND», «
	IF js IS NULL THEN
		mime := 'application/problem+json';
		js := '{"type": "about:blank", "title": "Not Found", "status": 404}';
	END IF;
»)dnl
define(«ERRVARS», «
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
»)dnl
define(«ERRCATCH», «
EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := '{"type": ' || to_json('http://www.postgresql.org/docs/9.3/static/errcodes-appendix.html#' || err_code)
		|| ', "title": ' || to_json(err_msg)
		|| ', "detail": ' || to_json(err_detail || err_context) || '}';
»)dnl
include(«schema.sql»)dnl
include(«views.sql»)dnl
include(«functions.sql»)dnl
include(«api.sql»)dnl
include(«fixtures.sql»)dnl
