/****************************************************************
 *								*
 * Copyright (c) 2018-2019 YottaDB LLC and/or its subsidiaries. *
 * All rights reserved.						*
 *								*
 *	This source code contains the intellectual property	*
 *	of its copyright holder(s), and is made available	*
 *	under a license.  If you do not know the terms of	*
 *	the license, please stop and do not read further.	*
 *								*
 ****************************************************************/

#include "mdef.h"

#include "libyottadb_int.h"
#include "gtmci.h"

#ifdef DEBUG
GBLREF	boolean_t	noThreadAPI_active;
GBLREF	boolean_t	simpleThreadAPI_active;
#endif

/* Helper routine to do a "ydb_ci_t" or "ydb_cip_t" call with a "ydb_simpleapi_ch" condition handler wrapper
 * to handle TPRETRY/TPRESTART.
 */
int ydb_cip_helper(int calltyp, ci_name_descriptor *ci_info, va_list *var)
{
	mval		src, dst;
	boolean_t	error_encountered;
	int		status;
	DCL_THREADGBL_ACCESS;

	SETUP_THREADGBL_ACCESS;
	/* Verify entry conditions, make sure YDB CI environment is up etc. */
	assert((LYDB_RTN_YDB_CI == calltyp) || (LYDB_RTN_YDB_CIP == calltyp));
	assert(simpleThreadAPI_active && !noThreadAPI_active);	/* Assert we are in SimpleThreadAPI mode. Caller ensures that. */
	LIBYOTTADB_INIT(calltyp, (int));	/* Note: macro could "return" from this function in case of errors */
	assert(0 == TREF(sapi_mstrs_for_gc_indx));	/* previously unused entries should have been cleared by that
							 * corresponding ydb_*_s() call.
							 */
	ESTABLISH_NORET(ydb_simpleapi_ch, error_encountered);
	if (error_encountered)
	{
		assert(0 == TREF(sapi_mstrs_for_gc_indx));	/* should have been cleared by "ydb_simpleapi_ch" */
		REVERT;
		/* Note: Since "ydb_ci" and "ydb_cip" pre-date the SimpleAPI, we do not negate TREF(ydb_error_code)
		 * before returning like is done in various SimpleAPI functions (e.g. "ydb_data_s"). Returning
		 * the negated value would break backward compatibility.
		 */
		return ((ERR_TPRETRY == SIGNAL) ? ERR_TPRETRY : TREF(ydb_error_code));
	}
	status = ydb_ci_exec(ci_info->rtn_name.address, ci_info, *var, FALSE);
	assert(0 == TREF(sapi_mstrs_for_gc_indx));	/* the counter should have never become non-zero in this function */
	LIBYOTTADB_DONE;
	REVERT;
	return status;
}
