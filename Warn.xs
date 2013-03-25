#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "ap_mmn.h"
#include "httpd.h"
#include "http_config.h"
#include "http_log.h"
#include "http_protocol.h"
#include "http_main.h"
#include "http_request.h"
#include "http_connection.h"
#include "http_core.h"
#include "http_vhost.h"
#include "ap_mpm.h"
#include "modperl_global.h"

/*
AP_DECLARE(void) ap_log_rerror(const char *file, int line, int level,
                               apr_status_t status, const request_rec *r,
                               const char *fmt, ...)
*/

static request_rec *xs_sv2request_rec(pTHX_ SV *in) {
	SV *sv = Nullsv;
	MAGIC *mg;
	if (SvROK(in)) {
		SV *rv = (SV*)SvRV(in);
		//warn("svrok");
		switch (SvTYPE(rv)) {
			case SVt_PVMG:
				//warn("svrok: pvmg");
				sv = rv;
				break;
			default:
				Perl_croak(aTHX_ "panic: unsupported request_rec type %d",
					(int)SvTYPE(rv));
		}
	}
	/* there could be pool magic attached to custom $r object, so make
	 * sure that mg->mg_ptr is set */
	if ((mg = mg_find(sv, PERL_MAGIC_ext)) && mg->mg_ptr) {
		//warn("mg_ptr");
		return (request_rec *)mg->mg_ptr;
	}
	else {
		//warn("int2ptr");
		return INT2PTR(request_rec *, SvIV(sv));
	}
	return NULL;
}


MODULE = Apache2::Warn		PACKAGE = Apache2::Warn

void warn(...)
CODE:
	server_rec  *s;
	request_rec *r;
	conn_rec    *c;
	SV *msg;
	
	if (items > 0) {
		int i;
		msg = sv_2mortal( newSV(128) );
		SvUPGRADE( msg, SVt_PV );
		for( i = 0; i < items; i++ ) {
			sv_catsv( msg, ST(i) );
		}
	} else {
		msg = sv_2mortal( newSV(128) );
		SvUPGRADE( msg, SVt_PV );
	}
	if ( SvCUR( msg ) == 0 || ( SvCUR( msg ) == 1 && SvPVX(msg)[SvCUR(msg) - 1] == '\n' ) ) {
		sv_setpv(msg,"Warning: something wrong");
	}
	if ( SvPVX(msg)[SvCUR(msg) - 1] == '\n' ) {
		SvCUR_set(msg, SvCUR(msg) - 1);
		SvPVX(msg)[SvCUR(msg)] = 0;
	} else {
		sv_catpvf(msg, " at %s line %d.", CopFILE(PL_curcop), CopLINE(PL_curcop));
	}
	
	(void)modperl_tls_get_request_rec(&r);
	if (!r) {
		s = modperl_global_get_server_rec();
		if (!s) {
			(void)Perl_croak(aTHX_ "panic: no request_rec, no server_rec for warn call");
		}
		ap_log_error(APLOG_MARK, APLOG_ERR | APLOG_NOERRNO, 0, s, "test: %s",SvPVX(msg));
		XSRETURN_UNDEF;
	}
	c = r->connection;
	r->connection = 0;
	ap_log_rerror(APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO | APLOG_STARTUP, 0, r, "%s",SvPVX(msg));
	r->connection = c;
	XSRETURN_UNDEF;

void rwarn(SV * rsv, ...)
CODE:
	request_rec *r;
	conn_rec    *c;
	SV *msg;
	
	r = xs_sv2request_rec(aTHX_ rsv);
	//modperl_tls_get_request_rec(&r);
	if (!r) {
		Perl_croak(aTHX_ "panic: request not passed to Apache2::Warn::warn call");
	}
	
	if (items > 1) {
		int i;
		msg = sv_2mortal( newSV(128) );
		SvUPGRADE( msg, SVt_PV );
		for( i = 1; i < items; i++ ) {
			sv_catsv( msg, ST(i) );
		}
	} else {
		msg = sv_2mortal( newSV(128) );
		SvUPGRADE( msg, SVt_PV );
	}
	if ( SvCUR( msg ) == 0 || ( SvCUR( msg ) == 1 && SvPVX(msg)[SvCUR(msg) - 1] == '\n' ) ) {
		sv_setpv(msg,"Warning: something wrong");
	}
	if ( SvPVX(msg)[SvCUR(msg) - 1] == '\n' ) {
		SvCUR_set(msg, SvCUR(msg) - 1);
		SvPVX(msg)[SvCUR(msg)] = 0;
	} else {
		sv_catpvf(msg, " at %s line %d.", CopFILE(PL_curcop), CopLINE(PL_curcop));
	}
	
	
	c = r->connection;
	r->connection = 0;
	ap_log_rerror(APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO | APLOG_STARTUP, 0, r, "%s",SvPVX( msg ));
	r->connection = c;
	XSRETURN_UNDEF;
