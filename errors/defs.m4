changequote(«, »)dnl
define(«_NOTFOUND», «
	IF js IS NULL THEN
		mime := 'application/problem+json';
		js := '{"type": "about:blank", "title": "Not Found", "status": 404}';
	END IF;
»)dnl
define(«_ERRVARS», «
	err_code text;
	err_col text;
	err_cnstrnt text;
	err_datatype text;
	err_msg text;
	err_tbl text;
	err_detail text;
	err_hint text;
	err_context text;
»)dnl
define(«_ERRCATCH», «
EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS
	err_code = RETURNED_SQLSTATE,
	err_col = COLUMN_NAME,
	err_cnstrnt = CONSTRAINT_NAME,
	err_datatype = PG_DATATYPE_NAME,
	err_msg = MESSAGE_TEXT,
	err_tbl = TABLE_NAME,
	err_detail = PG_EXCEPTION_DETAIL,
	err_hint = PG_EXCEPTION_HINT,
	err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := err2json(code := err_code,
		col := err_col,
		cnstrnt := err_cnstrnt,
		datatype := err_datatype,
		msg := err_msg,
		tbl := err_tbl,
		detail := err_detail,
		hint := err_hint,
		context := err_context);
»)dnl
include(«sql.m4.sql»)dnl
